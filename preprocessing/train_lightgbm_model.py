#!/usr/bin/env python3
"""
Train LightGBM model for hybrid optimizer routing
"""

import os
import sys
import json
import numpy as np
import pandas as pd
import lightgbm as lgb
from sklearn.model_selection import train_test_split, KFold
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import argparse
import logging
from pathlib import Path
import pickle

class LightGBMTrainer:
    def __init__(self, data_path, output_dir='./models'):
        self.data_path = Path(data_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.logger = self._setup_logging()
        
    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        return logging.getLogger(__name__)
    
    def load_data(self):
        """Load training data from CSV"""
        self.logger.info(f"Loading data from {self.data_path}")
        
        df = pd.read_csv(self.data_path)
        
        # Separate features, labels, and latencies
        feature_cols = [col for col in df.columns if col.startswith('f')]
        X = df[feature_cols].values
        y = df['label'].values
        
        # Store latencies for analysis
        self.row_latencies = df['row_latency'].values
        self.col_latencies = df['col_latency'].values
        
        self.logger.info(f"Loaded {len(X)} samples with {X.shape[1]} features")
        self.logger.info(f"Class distribution: {np.bincount(y)}")
        
        return X, y
    
    def prepare_datasets(self, X, y, test_size=0.2, val_size=0.1):
        """Split data into train, validation, and test sets"""
        # First split: train+val vs test
        X_temp, X_test, y_temp, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
        
        # Second split: train vs val
        val_ratio = val_size / (1 - test_size)
        X_train, X_val, y_train, y_val = train_test_split(
            X_temp, y_temp, test_size=val_ratio, random_state=42, stratify=y_temp
        )
        
        self.logger.info(f"Train set: {len(X_train)} samples")
        self.logger.info(f"Val set: {len(X_val)} samples")
        self.logger.info(f"Test set: {len(X_test)} samples")
        
        return X_train, X_val, X_test, y_train, y_val, y_test
    
    def train_classifier(self, X_train, y_train, X_val, y_val):
        """Train binary classifier for routing decision"""
        # Create LightGBM datasets
        train_data = lgb.Dataset(X_train, label=y_train)
        val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)
        
        # Parameters for binary classification
        params = {
            'objective': 'binary',
            'metric': ['binary_logloss', 'auc'],
            'boosting_type': 'gbdt',
            'num_leaves': 31,
            'learning_rate': 0.05,
            'feature_fraction': 0.9,
            'bagging_fraction': 0.8,
            'bagging_freq': 5,
            'verbose': 0,
            'random_state': 42,
            'n_jobs': -1
        }
        
        # Train model
        self.logger.info("Training classifier model...")
        callbacks = [
            lgb.early_stopping(stopping_rounds=50),
            lgb.log_evaluation(period=100)
        ]
        
        model = lgb.train(
            params,
            train_data,
            num_boost_round=1000,
            valid_sets=[val_data],
            callbacks=callbacks
        )
        
        return model
    
    def train_regression(self, X_train, y_train, X_val, y_val, target='latency_diff'):
        """Train regression model for latency prediction"""
        # Compute target values
        if target == 'latency_diff':
            # Predict difference: col_latency - row_latency
            train_target = self.col_latencies[:len(y_train)] - self.row_latencies[:len(y_train)]
            val_target = self.col_latencies[len(y_train):len(y_train)+len(y_val)] - \
                        self.row_latencies[len(y_train):len(y_train)+len(y_val)]
        elif target == 'log_ratio':
            # Predict log ratio
            train_target = np.log1p(self.col_latencies[:len(y_train)]) - \
                          np.log1p(self.row_latencies[:len(y_train)])
            val_target = np.log1p(self.col_latencies[len(y_train):len(y_train)+len(y_val)]) - \
                        np.log1p(self.row_latencies[len(y_train):len(y_train)+len(y_val)])
        
        # Create datasets
        train_data = lgb.Dataset(X_train, label=train_target)
        val_data = lgb.Dataset(X_val, label=val_target, reference=train_data)
        
        # Parameters for regression
        params = {
            'objective': 'regression',
            'metric': ['rmse', 'mae'],
            'boosting_type': 'gbdt',
            'num_leaves': 31,
            'learning_rate': 0.05,
            'feature_fraction': 0.9,
            'bagging_fraction': 0.8,
            'bagging_freq': 5,
            'verbose': 0,
            'random_state': 42,
            'n_jobs': -1
        }
        
        self.logger.info("Training regression model...")
        callbacks = [
            lgb.early_stopping(stopping_rounds=50),
            lgb.log_evaluation(period=100)
        ]
        
        model = lgb.train(
            params,
            train_data,
            num_boost_round=1000,
            valid_sets=[val_data],
            callbacks=callbacks
        )
        
        return model
    
    def evaluate_model(self, model, X_test, y_test, model_type='classifier'):
        """Evaluate model performance"""
        if model_type == 'classifier':
            # Get predictions
            y_pred_proba = model.predict(X_test, num_iteration=model.best_iteration)
            y_pred = (y_pred_proba >= 0.5).astype(int)
            
            # Calculate metrics
            metrics = {
                'accuracy': accuracy_score(y_test, y_pred),
                'precision': precision_score(y_test, y_pred),
                'recall': recall_score(y_test, y_pred),
                'f1': f1_score(y_test, y_pred),
                'auc': roc_auc_score(y_test, y_pred_proba)
            }
            
            self.logger.info("Classification Metrics:")
            for metric, value in metrics.items():
                self.logger.info(f"  {metric}: {value:.4f}")
                
        else:  # regression
            y_pred = model.predict(X_test, num_iteration=model.best_iteration)
            
            # Calculate metrics
            from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
            
            metrics = {
                'rmse': np.sqrt(mean_squared_error(y_test, y_pred)),
                'mae': mean_absolute_error(y_test, y_pred),
                'r2': r2_score(y_test, y_pred)
            }
            
            self.logger.info("Regression Metrics:")
            for metric, value in metrics.items():
                self.logger.info(f"  {metric}: {value:.4f}")
        
        return metrics
    
    def analyze_feature_importance(self, model, top_n=32):
        """Analyze and plot feature importance"""
        importance = model.feature_importance(importance_type='split')
        feature_indices = list(range(len(importance)))
        
        # Create importance dataframe with indices
        importance_df = pd.DataFrame({
            'feature_idx': feature_indices,
            'feature_name': [f'f{i}' for i in feature_indices],
            'importance': importance
        }).sort_values('importance', ascending=False)
        
        # Save all feature importances
        importance_df.to_csv(self.output_dir / 'all_features_importance.csv', index=False)
        
        # Get top features
        top_features = importance_df.head(top_n)
        top_features.to_csv(self.output_dir / 'top_features.csv', index=False)
        
        # Save top feature indices for C++ integration
        top_indices = top_features['feature_idx'].values
        indices_file = self.output_dir / 'top_feature_indices.txt'
        with open(indices_file, 'w') as f:
            for idx in top_indices:
                f.write(f"{idx}\n")
        self.logger.info(f"Top feature indices saved to {indices_file}")
        
        # Plot importance
        plt.figure(figsize=(10, 8))
        plt.barh(range(top_n), top_features['importance'].values)
        plt.yticks(range(top_n), top_features['feature_name'].values)
        plt.xlabel('Feature Importance')
        plt.title(f'Top {top_n} Most Important Features')
        plt.tight_layout()
        plt.savefig(self.output_dir / 'feature_importance.png')
        plt.close()
        
        self.logger.info(f"Top 10 features (indices): {top_indices[:10].tolist()}")
        self.logger.info(f"Top 10 features (names): {top_features.head(10)['feature_name'].tolist()}")
        
        return importance_df, top_indices
    
    def cross_validate(self, X, y, n_folds=5):
        """Perform cross-validation"""
        kf = KFold(n_splits=n_folds, shuffle=True, random_state=42)
        cv_scores = []
        
        for fold, (train_idx, val_idx) in enumerate(kf.split(X)):
            X_train, X_val = X[train_idx], X[val_idx]
            y_train, y_val = y[train_idx], y[val_idx]
            
            # Train model
            train_data = lgb.Dataset(X_train, label=y_train)
            val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)
            
            params = {
                'objective': 'binary',
                'metric': 'auc',
                'boosting_type': 'gbdt',
                'num_leaves': 31,
                'learning_rate': 0.05,
                'verbose': -1,
                'random_state': 42
            }
            
            model = lgb.train(
                params,
                train_data,
                num_boost_round=1000,
                valid_sets=[val_data],
                callbacks=[lgb.early_stopping(50), lgb.log_evaluation(0)]
            )
            
            # Evaluate
            y_pred_proba = model.predict(X_val, num_iteration=model.best_iteration)
            auc_score = roc_auc_score(y_val, y_pred_proba)
            cv_scores.append(auc_score)
            
            self.logger.info(f"Fold {fold+1} AUC: {auc_score:.4f}")
        
        self.logger.info(f"Mean CV AUC: {np.mean(cv_scores):.4f} (+/- {np.std(cv_scores):.4f})")
        
        return cv_scores
    
    def save_model(self, model, model_name='hybrid_optimizer_model'):
        """Save trained model"""
        model_path = self.output_dir / f'{model_name}.txt'
        model.save_model(str(model_path))
        self.logger.info(f"Model saved to {model_path}")
        
        # Also save as C++ code for integration
        cpp_path = self.output_dir / f'{model_name}.cpp'
        with open(cpp_path, 'w') as f:
            f.write(model.model_to_string())
        self.logger.info(f"C++ model code saved to {cpp_path}")
        
    def train_with_feature_selection(self, X_train, y_train, X_val, y_val, 
                                    top_n=32, selection_threshold=None):
        """Train model with automatic feature selection"""
        # Step 1: Train on all features to get importance
        self.logger.info("Step 1: Training on all features to determine importance...")
        full_model = self.train_classifier(X_train, y_train, X_val, y_val)
        
        # Step 2: Analyze feature importance
        importance_df, top_indices = self.analyze_feature_importance(full_model, top_n)
        
        # Optional: Use importance threshold instead of fixed top_n
        if selection_threshold is not None:
            max_importance = importance_df['importance'].max()
            threshold = max_importance * selection_threshold
            selected = importance_df[importance_df['importance'] >= threshold]
            top_indices = selected['feature_idx'].values
            self.logger.info(f"Selected {len(top_indices)} features with importance >= {threshold:.2f}")
        
        # Step 3: Retrain on selected features
        self.logger.info(f"Step 2: Retraining on top {len(top_indices)} features...")
        X_train_selected = X_train[:, top_indices]
        X_val_selected = X_val[:, top_indices]
        
        selected_model = self.train_classifier(X_train_selected, y_train, X_val_selected, y_val)
        
        return selected_model, top_indices, full_model
        
    def run_training_pipeline(self, use_feature_selection=True, top_n_features=32):
        """Run complete training pipeline with optional feature selection"""
        # Load data
        X, y = self.load_data()
        
        # Prepare datasets
        X_train, X_val, X_test, y_train, y_val, y_test = self.prepare_datasets(X, y)
        
        if use_feature_selection:
            # Train with feature selection
            selected_model, top_indices, full_model = self.train_with_feature_selection(
                X_train, y_train, X_val, y_val, top_n=top_n_features
            )
            
            # Evaluate both models
            self.logger.info("\n=== Full Model Evaluation (140 features) ===")
            full_metrics = self.evaluate_model(full_model, X_test, y_test, 'classifier')
            
            self.logger.info(f"\n=== Selected Model Evaluation ({len(top_indices)} features) ===")
            X_test_selected = X_test[:, top_indices]
            selected_metrics = self.evaluate_model(selected_model, X_test_selected, y_test, 'classifier')
            
            # Compare performance
            self.logger.info("\n=== Performance Comparison ===")
            self.logger.info(f"Full model AUC: {full_metrics['auc']:.4f}")
            self.logger.info(f"Selected model AUC: {selected_metrics['auc']:.4f}")
            self.logger.info(f"Feature reduction: {X.shape[1]} -> {len(top_indices)}")
            
            # Save selected model and indices
            self.save_model(selected_model, 'hybrid_optimizer_selected')
            self.save_model(full_model, 'hybrid_optimizer_full')
            
            # Save metrics
            metrics_summary = {
                'full_model_metrics': full_metrics,
                'selected_model_metrics': selected_metrics,
                'num_features_full': X.shape[1],
                'num_features_selected': len(top_indices),
                'selected_feature_indices': top_indices.tolist(),
                'performance_delta': selected_metrics['auc'] - full_metrics['auc']
            }
            
            final_model = selected_model
            
        else:
            # Train without feature selection (baseline)
            clf_model = self.train_classifier(X_train, y_train, X_val, y_val)
            
            # Evaluate
            self.logger.info("\nEvaluating classifier on test set:")
            clf_metrics = self.evaluate_model(clf_model, X_test, y_test, 'classifier')
            
            # Analyze feature importance
            self.logger.info("\nAnalyzing feature importance:")
            importance_df, top_indices = self.analyze_feature_importance(clf_model, top_n_features)
            
            # Save model
            self.save_model(clf_model, 'hybrid_optimizer_classifier')
            
            metrics_summary = {
                'classifier_metrics': clf_metrics,
                'top_feature_indices': top_indices.tolist()
            }
            
            final_model = clf_model
        
        # Cross-validation on final model
        self.logger.info("\nPerforming 5-fold cross-validation on final model...")
        if use_feature_selection:
            X_cv = X[:, top_indices]
        else:
            X_cv = X
        cv_scores = self.cross_validate(X_cv, y)
        
        metrics_summary['cv_scores'] = cv_scores
        metrics_summary['cv_mean'] = float(np.mean(cv_scores))
        metrics_summary['cv_std'] = float(np.std(cv_scores))
        
        # Save final metrics
        metrics_path = self.output_dir / 'training_metrics.json'
        with open(metrics_path, 'w') as f:
            json.dump(metrics_summary, f, indent=2)
        
        self.logger.info(f"\nTraining complete! Results saved to {self.output_dir}")
        
        return final_model, metrics_summary


def main():
    parser = argparse.ArgumentParser(description='Train LightGBM model for hybrid optimizer')
    parser.add_argument('--data', type=str, required=True,
                       help='Path to training data CSV')
    parser.add_argument('--output', type=str, default='./models',
                       help='Output directory for models')
    parser.add_argument('--cv-only', action='store_true',
                       help='Only run cross-validation')
    parser.add_argument('--no-feature-selection', action='store_true',
                       help='Train without feature selection (use all features)')
    parser.add_argument('--top-n', type=int, default=32,
                       help='Number of top features to select (default: 32)')
    parser.add_argument('--importance-threshold', type=float, default=None,
                       help='Select features with importance >= max_importance * threshold')
    
    args = parser.parse_args()
    
    trainer = LightGBMTrainer(args.data, args.output)
    
    if args.cv_only:
        X, y = trainer.load_data()
        trainer.cross_validate(X, y)
    else:
        use_feature_selection = not args.no_feature_selection
        trainer.run_training_pipeline(
            use_feature_selection=use_feature_selection,
            top_n_features=args.top_n
        )


if __name__ == "__main__":
    main()
