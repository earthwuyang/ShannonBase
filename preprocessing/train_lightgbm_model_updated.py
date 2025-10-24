#!/usr/bin/env python3
"""
Updated LightGBM training script for hybrid optimizer routing
Processes JSON results files directly from collect_dual_engine_data.py
"""

import os
import sys
import json
import numpy as np
import pandas as pd
import lightgbm as lgb
from sklearn.model_selection import train_test_split, KFold
from sklearn.metrics import (accuracy_score, precision_score, recall_score, f1_score,
                           roc_auc_score, confusion_matrix, classification_report)
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
try:
    import seaborn as sns
    HAS_SEABORN = True
except ImportError:
    HAS_SEABORN = False
import argparse
import logging
from pathlib import Path
import pickle
from collections import defaultdict
import glob

class LightGBMTrainerUpdated:
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

    def process_results_files(self):
        """Process JSON results files and create training dataset"""
        self.logger.info(f"Processing results files from {self.data_path}")

        results_files = list(self.data_path.glob('q_*_results.json'))
        self.logger.info(f"Found {len(results_files)} results files")

        if not results_files:
            self.logger.error("No results files found!")
            return None

        training_data = []

        for i, result_file in enumerate(results_files):
            if i % 1000 == 0:
                self.logger.info(f"Processing file {i+1}/{len(results_files)}")

            try:
                with open(result_file) as f:
                    data = json.load(f)

                # Extract features and latencies
                query_id = data.get('query_id', '')
                database = data.get('database', 'unknown')

                # Check if we have both MySQL and ShannonBase data
                if 'mysql' not in data or 'shannonbase' not in data:
                    continue

                mysql_data = data['mysql']
                shannonbase_data = data['shannonbase']

                # Skip if either engine failed
                if 'error' in mysql_data or 'error' in shannonbase_data:
                    continue

                # Extract features (use MySQL features as baseline)
                features = mysql_data.get('features', [])
                if not features or len(features) == 0:
                    continue

                # Extract latencies
                mysql_latency = mysql_data.get('latency', {}).get('mean_ms', 0)
                shannonbase_latency = shannonbase_data.get('latency', {}).get('mean_ms', 0)

                if mysql_latency <= 0 or shannonbase_latency <= 0:
                    continue

                # Create label: 1 = ShannonBase (Rapid) is better, 0 = MySQL (InnoDB) is better
                label = 1 if shannonbase_latency < mysql_latency else 0

                # Create training sample
                sample = {
                    'query_id': query_id,
                    'database': database,
                    'label': label,
                    'row_latency': mysql_latency,
                    'col_latency': shannonbase_latency,
                    'speedup_ratio': mysql_latency / max(shannonbase_latency, 0.001)
                }

                # Add feature columns (f0, f1, ..., f31 for 32 features)
                for j, feature_val in enumerate(features):
                    sample[f'f{j}'] = feature_val

                training_data.append(sample)

            except Exception as e:
                self.logger.warning(f"Error processing {result_file}: {e}")
                continue

        self.logger.info(f"Successfully processed {len(training_data)} valid queries")

        if not training_data:
            self.logger.error("No valid training data found!")
            return None

        # Convert to DataFrame
        df = pd.DataFrame(training_data)

        # Analyze class distribution
        col_better_count = df['label'].sum()
        row_better_count = len(df) - col_better_count

        self.logger.info(f"\nTraining data summary:")
        self.logger.info(f"Total samples: {len(df)}")
        self.logger.info(f"ShannonBase (Rapid) better: {col_better_count} ({col_better_count/len(df)*100:.1f}%)")
        self.logger.info(f"MySQL (InnoDB) better: {row_better_count} ({row_better_count/len(df)*100:.1f}%)")

        # Analyze latency statistics
        self.logger.info(f"\nLatency statistics:")
        self.logger.info(f"Mean MySQL latency: {df['row_latency'].mean():.2f} ms")
        self.logger.info(f"Mean ShannonBase latency: {df['col_latency'].mean():.2f} ms")
        self.logger.info(f"Median speedup ratio: {df['speedup_ratio'].median():.2f}x")
        self.logger.info(f"95th percentile speedup: {df['speedup_ratio'].quantile(0.95):.2f}x")

        # Analyze by database
        self.logger.info(f"\nDatabase distribution:")
        db_counts = df['database'].value_counts()
        for db, count in db_counts.items():
            db_ratio = count / len(df) * 100
            self.logger.info(f"  {db}: {count} ({db_ratio:.1f}%)")

        return df

    def save_dataset(self, df, output_path):
        """Save dataset to CSV for compatibility with original training script"""
        df.to_csv(output_path, index=False)
        self.logger.info(f"Dataset saved to {output_path}")

        # Also save a summary
        summary = {
            'total_samples': len(df),
            'feature_count': len([col for col in df.columns if col.startswith('f')]),
            'class_distribution': {
                'shannonbase_better': int(df['label'].sum()),
                'mysql_better': int(len(df) - df['label'].sum())
            },
            'latency_stats': {
                'mysql_mean_ms': float(df['row_latency'].mean()),
                'shannonbase_mean_ms': float(df['col_latency'].mean()),
                'median_speedup': float(df['speedup_ratio'].median())
            }
        }

        summary_path = output_path.parent / 'dataset_summary.json'
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)

        self.logger.info(f"Dataset summary saved to {summary_path}")

    def prepare_datasets(self, df, test_size=0.2, val_size=0.1):
        """Split data into train, validation, and test sets - handle extremely small datasets"""
        # Extract features and labels
        feature_cols = [col for col in df.columns if col.startswith('f')]
        X = df[feature_cols].values
        y = df['label'].values

        # Store latencies for analysis
        self.row_latencies = df['row_latency'].values
        self.col_latencies = df['col_latency'].values
        self.query_ids = df['query_id'].values

        self.logger.info(f"Dataset shape: {X.shape}")
        self.logger.info(f"Features: {len(feature_cols)}")
        self.logger.info(f"Label distribution: {np.bincount(y)}")

        # Handle extremely small datasets
        n_samples = len(y)
        if n_samples < 6:  # Too few for stratified splitting
            self.logger.warning(f"Extremely small dataset ({n_samples} samples). Using simple splitting.")

            # Use simple splitting without stratification
            if n_samples >= 3:
                # Split into train+val vs test first
                test_size_actual = max(1, int(n_samples * test_size))
                if test_size_actual >= n_samples - 1:
                    test_size_actual = 1  # Ensure at least 1 sample for training

                # Simple split by index
                indices = np.random.RandomState(42).permutation(n_samples)
                test_idx = indices[:test_size_actual]
                remaining_idx = indices[test_size_actual:]

                # Split remaining into train vs val
                val_size_actual = max(1, int(len(remaining_idx) * val_size))
                if val_size_actual >= len(remaining_idx):
                    val_size_actual = max(1, len(remaining_idx) - 1)

                val_idx = remaining_idx[:val_size_actual]
                train_idx = remaining_idx[val_size_actual:]

                X_train, X_val, X_test = X[train_idx], X[val_idx], X[test_idx]
                y_train, y_val, y_test = y[train_idx], y[val_idx], y[test_idx]
            else:
                # Even smaller - use all data for training, no validation/test
                self.logger.warning("Dataset too small for splitting. Using all data for training.")
                X_train, X_val, X_test = X, X, X
                y_train, y_val, y_test = y, y, y
        else:
            # Normal stratified splitting for larger datasets
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

    def train_ensemble(self, X_train, y_train, X_val, y_val):
        """Train ensemble of models for extreme imbalance - bagging with different seeds"""
        self.logger.info(f"Training ensemble with {len(X_train)} samples")

        # Create multiple models with different random seeds
        models = []
        n_models = 5  # Number of ensemble members

        for i in range(n_models):
            self.logger.info(f"Training ensemble model {i+1}/{n_models}")

            # Create bootstrap sample with replacement
            n_samples = len(X_train)
            indices = np.random.choice(n_samples, size=n_samples, replace=True)
            X_boot = X_train[indices]
            y_boot = y_train[indices]

            # Train individual model
            model = self.train_single_classifier(X_boot, y_boot, X_val, y_val, seed=42+i)
            models.append(model)

        return models

    def train_single_classifier(self, X_train, y_train, X_val, y_val, seed=42):
        """Train single classifier with specific seed for ensemble"""
        # Create LightGBM datasets
        train_data = lgb.Dataset(X_train, label=y_train)
        val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

        # Parameters for extreme class imbalance
        params = {
            'objective': 'binary',
            'metric': ['binary_logloss', 'auc'],
            'boosting_type': 'gbdt',
            'num_leaves': 3,
            'learning_rate': 0.3,
            'feature_fraction': 1.0,
            'bagging_fraction': 1.0,
            'min_data_in_leaf': 1,
            'min_data_in_bin': 1,
            'min_gain_to_split': 0.0,
            'lambda_l1': 0.0,
            'lambda_l2': 0.0,
            'verbose': 0,
            'random_state': seed,
            'n_jobs': 1,  # Single thread for reproducibility
            'is_unbalance': True
        }

        # Train model
        model = lgb.train(
            params,
            train_data,
            num_boost_round=100,
            valid_sets=[val_data],
            callbacks=[lgb.early_stopping(stopping_rounds=20, verbose=False)]
        )

        return model

    def train_classifier(self, X_train, y_train, X_val, y_val):
        """Train binary classifier for routing decision - optimized for extreme class imbalance"""
        self.logger.info(f"Training classifier with {len(X_train)} samples")
        self.logger.info(f"Class distribution - Train: {np.bincount(y_train)}")
        self.logger.info(f"Class distribution - Val: {np.bincount(y_val)}")

        # Check for severe class imbalance
        class_counts = np.bincount(y_train)
        if len(class_counts) > 1 and min(class_counts) < 2:
            self.logger.warning("Severe class imbalance detected. Using aggressive balancing strategy.")

        # Create LightGBM datasets with aggressive class balancing
        if len(class_counts) > 1:
            # Calculate aggressive class weights (inverse frequency squared)
            total = len(y_train)
            class_weights = {}
            for i, count in enumerate(class_counts):
                if count > 0:
                    # Use inverse frequency with amplification for minority class
                    weight = (total / count) ** 0.7  # Amplify minority class
                    class_weights[i] = max(weight, 1.0)
                else:
                    class_weights[i] = 1.0

            self.logger.info(f"Aggressive class weights: {class_weights}")

            # Apply weights to training data
            sample_weights = np.array([class_weights[label] for label in y_train])
            train_data = lgb.Dataset(X_train, label=y_train, weight=sample_weights)
        else:
            train_data = lgb.Dataset(X_train, label=y_train)

        val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

        # Parameters for extreme class imbalance - focus on minority class recall
        params = {
            'objective': 'binary',
            'metric': ['binary_logloss', 'auc', 'recall'],  # Add recall metric
            'boosting_type': 'gbdt',
            'num_leaves': 3,           # Minimal leaves to force splits
            'learning_rate': 0.3,      # High learning rate for aggressive learning
            'feature_fraction': 1.0,   # Use all features
            'bagging_fraction': 1.0,   # No bagging
            'min_data_in_leaf': 1,     # Allow single samples
            'min_data_in_bin': 1,      # Allow single samples per bin
            'min_gain_to_split': 0.0,  # Allow any gain splits
            'lambda_l1': 0.0,          # No regularization
            'lambda_l2': 0.0,          # No regularization
            'verbose': 0,
            'random_state': 42,
            'n_jobs': -1,
            'is_unbalance': True,      # Built-in imbalance handling
            'scale_pos_weight': max(class_counts[0]/max(class_counts[1],1), 1) if len(class_counts) > 1 else 1.0
        }

        # Train model with minimal early stopping for maximum learning
        self.logger.info("Training classifier model with aggressive imbalance handling...")
        callbacks = [
            lgb.early_stopping(stopping_rounds=50, verbose=False),  # Allow more rounds
            lgb.log_evaluation(period=5)  # More frequent logging
        ]

        model = lgb.train(
            params,
            train_data,
            num_boost_round=200,  # Increased maximum rounds
            valid_sets=[val_data],
            callbacks=callbacks
        )

        return model

    def evaluate_ensemble(self, models, X_test, y_test, model_name="LightGBM Ensemble"):
        """Evaluate ensemble of models with voting"""
        # Get predictions from all models
        predictions = []
        probabilities = []

        for model in models:
            y_pred_proba = model.predict(X_test, num_iteration=model.best_iteration)
            y_pred = (y_pred_proba >= 0.5).astype(int)
            predictions.append(y_pred)
            probabilities.append(y_pred_proba)

        # Majority voting for predictions
        ensemble_pred = np.round(np.mean(predictions, axis=0)).astype(int)

        # Average probabilities
        ensemble_proba = np.mean(probabilities, axis=0)

        # Calculate metrics
        metrics = {
            'accuracy': accuracy_score(y_test, ensemble_pred),
            'precision': precision_score(y_test, ensemble_pred, zero_division=0),
            'recall': recall_score(y_test, ensemble_pred, zero_division=0),
            'f1': f1_score(y_test, ensemble_pred, zero_division=0),
            'auc': roc_auc_score(y_test, ensemble_proba)
        }

        # Calculate confusion matrix
        cm = confusion_matrix(y_test, ensemble_pred)

        self.logger.info(f"\n=== {model_name} Classification Metrics ===")
        self.logger.info(f"  Accuracy: {metrics['accuracy']:.4f}")
        self.logger.info(f"  Precision: {metrics['precision']:.4f}")
        self.logger.info(f"  Recall: {metrics['recall']:.4f}")
        self.logger.info(f"  F1-Score: {metrics['f1']:.4f}")
        self.logger.info(f"  AUC: {metrics['auc']:.4f}")

        self.logger.info(f"\n{model_name} Confusion Matrix:")
        self.logger.info(f"                 Predicted")
        self.logger.info(f"                 Rapid  MySQL")
        self.logger.info(f"Actual Rapid    {cm[1,1]:6d} {cm[1,0]:6d}")
        self.logger.info(f"Actual MySQL    {cm[0,1]:6d} {cm[0,0]:6d}")

        # Calculate additional metrics from confusion matrix
        if cm.size == 4:  # 2x2 matrix
            tn, fp, fn, tp = cm.ravel()
            metrics['true_positives'] = int(tp)
            metrics['true_negatives'] = int(tn)
            metrics['false_positives'] = int(fp)
            metrics['false_negatives'] = int(fn)
        else:
            metrics['true_positives'] = 0
            metrics['true_negatives'] = 0
            metrics['false_positives'] = 0
            metrics['false_negatives'] = 0

        return metrics, cm

    def evaluate_model(self, model, X_test, y_test, model_name="LightGBM"):
        """Evaluate model performance with confusion matrix and threshold optimization"""
        # Get predictions
        y_pred_proba = model.predict(X_test, num_iteration=model.best_iteration)

        # Optimize threshold for extreme imbalance - focus on minority class recall
        best_threshold = 0.5
        best_f1 = 0.0
        best_metrics = None

        # Try different thresholds to optimize for minority class
        thresholds = np.arange(0.1, 0.9, 0.05)  # Wider range for extreme imbalance

        for threshold in thresholds:
            y_pred_thresh = (y_pred_proba >= threshold).astype(int)

            # Calculate metrics for this threshold
            accuracy = accuracy_score(y_test, y_pred_thresh)
            precision = precision_score(y_test, y_pred_thresh, zero_division=0)
            recall = recall_score(y_test, y_pred_thresh, zero_division=0)
            f1 = f1_score(y_test, y_pred_thresh, zero_division=0)

            # For extreme imbalance, prioritize recall over precision
            # Use weighted score that favors minority class detection
            minority_class_weight = 2.0 if np.sum(y_test == 1) < np.sum(y_test == 0) else 1.0
            weighted_score = recall * minority_class_weight + f1

            if weighted_score > best_f1:
                best_f1 = weighted_score
                best_threshold = threshold
                best_metrics = {
                    'threshold': threshold,
                    'accuracy': accuracy,
                    'precision': precision,
                    'recall': recall,
                    'f1': f1
                }

        # Use optimized threshold
        y_pred = (y_pred_proba >= best_threshold).astype(int)

        # Calculate final metrics
        metrics = {
            'accuracy': best_metrics['accuracy'],
            'precision': best_metrics['precision'],
            'recall': best_metrics['recall'],
            'f1': best_metrics['f1'],
            'auc': roc_auc_score(y_test, y_pred_proba),
            'optimal_threshold': best_threshold
        }

        # Calculate confusion matrix
        cm = confusion_matrix(y_test, y_pred)

        self.logger.info(f"\n=== {model_name} Classification Metrics (Threshold={best_threshold:.2f}) ===")
        self.logger.info(f"  Accuracy: {metrics['accuracy']:.4f}")
        self.logger.info(f"  Precision: {metrics['precision']:.4f}")
        self.logger.info(f"  Recall: {metrics['recall']:.4f}")
        self.logger.info(f"  F1-Score: {metrics['f1']:.4f}")
        self.logger.info(f"  AUC: {metrics['auc']:.4f}")
        self.logger.info(f"  Optimal Threshold: {metrics['optimal_threshold']:.3f}")

        self.logger.info(f"\n{model_name} Confusion Matrix:")
        self.logger.info(f"                 Predicted")
        self.logger.info(f"                 Rapid  MySQL")
        self.logger.info(f"Actual Rapid    {cm[1,1]:6d} {cm[1,0]:6d}")
        self.logger.info(f"Actual MySQL    {cm[0,1]:6d} {cm[0,0]:6d}")

        # Calculate additional metrics from confusion matrix
        if cm.size == 4:  # 2x2 matrix
            tn, fp, fn, tp = cm.ravel()
        else:
            # Handle edge case where one class is missing
            tn = fp = fn = tp = 0
            if cm.shape == (2, 2):
                tn, fp, fn, tp = cm[0,0], cm[0,1], cm[1,0], cm[1,1]

        metrics['true_positives'] = int(tp)
        metrics['true_negatives'] = int(tn)
        metrics['false_positives'] = int(fp)
        metrics['false_negatives'] = int(fn)
        metrics['confusion_matrix'] = cm.tolist()  # Store the actual matrix

        return metrics, cm

    def print_metrics_table(self, lightgbm_metrics, cost_threshold_results, best_threshold):
        """Print comprehensive metrics comparison table"""
        self.logger.info("\n" + "="*80)
        self.logger.info("COMPREHENSIVE ROUTING PERFORMANCE COMPARISON")
        self.logger.info("="*80)

        # Header
        self.logger.info(f"{'Method':<25} {'Accuracy':<10} {'Precision':<10} {'Recall':<10} {'F1-Score':<10} {'AUC':<10}")
        self.logger.info("-" * 80)

        # LightGBM results
        self.logger.info(f"{'LightGBM (All Features)':<25} {lightgbm_metrics['accuracy']:<10.4f} {lightgbm_metrics['precision']:<10.4f} {lightgbm_metrics['recall']:<10.4f} {lightgbm_metrics['f1']:<10.4f} {lightgbm_metrics['auc']:<10.4f}")

        # Cost threshold results
        for threshold in sorted(cost_threshold_results.keys()):
            metrics = cost_threshold_results[threshold]
            marker = " ⭐" if threshold == best_threshold else ""
            self.logger.info(f"{'Cost Threshold ' + str(threshold) + marker:<25} {metrics['accuracy']:<10.4f} {metrics['precision']:<10.4f} {metrics['recall']:<10.4f} {metrics['f1']:<10.4f} {'N/A':<10}")

        self.logger.info("-" * 80)

        # Best method comparison
        best_cost_metrics = cost_threshold_results[best_threshold]
        self.logger.info(f"\nBEST METHODS COMPARISON:")
        self.logger.info(f"LightGBM F1-Score:     {lightgbm_metrics['f1']:.4f}")
        self.logger.info(f"Best Cost Threshold F1: {best_cost_metrics['f1']:.4f} (threshold: {best_threshold})")
        self.logger.info(f"Improvement:           {lightgbm_metrics['f1'] - best_cost_metrics['f1']:.4f}")

        # Confusion matrices summary
        self.logger.info(f"\nCONFUSION MATRICES:")
        self.logger.info(f"LightGBM:  TP={lightgbm_metrics['true_positives']}, TN={lightgbm_metrics['true_negatives']}, FP={lightgbm_metrics['false_positives']}, FN={lightgbm_metrics['false_negatives']}")
        self.logger.info(f"Cost Best: TP={best_cost_metrics['true_positives']}, TN={best_cost_metrics['true_negatives']}, FP={best_cost_metrics['false_positives']}, FN={best_cost_metrics['false_negatives']}")

        self.logger.info("="*80)

    def plot_confusion_matrix(self, cm, model_name, save_path=None):
        """Plot confusion matrix"""
        plt.figure(figsize=(8, 6))

        if HAS_SEABORN:
            sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                       xticklabels=['MySQL', 'Rapid'],
                       yticklabels=['MySQL', 'Rapid'])
        else:
            # Fallback without seaborn
            plt.imshow(cm, interpolation='nearest', cmap='Blues')
            plt.colorbar()
            plt.clim(0, cm.max())

            # Add text annotations
            for i in range(cm.shape[0]):
                for j in range(cm.shape[1]):
                    plt.text(j, i, str(cm[i, j]), ha='center', va='center')

        plt.title(f'Confusion Matrix - {model_name}')
        plt.ylabel('Actual')
        plt.xlabel('Predicted')
        plt.xticks([0, 1], ['MySQL', 'Rapid'])
        plt.yticks([0, 1], ['MySQL', 'Rapid'])

        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            plt.close()
        else:
            plt.show()

    def cost_threshold_routing(self, mysql_costs, shannonbase_costs, threshold=10000):
        """Implement original ShannonBase cost threshold routing for comparison"""
        # Original routing: route to Rapid if MySQL cost > threshold
        # 1 = route to Rapid (ShannonBase), 0 = route to MySQL
        predictions = (mysql_costs > threshold).astype(int)

        # Calculate actual performance-based labels
        # 1 = ShannonBase is better (faster), 0 = MySQL is better
        actual_labels = (shannonbase_costs < mysql_costs).astype(int)

        return predictions, actual_labels

    def evaluate_cost_threshold(self, mysql_costs, shannonbase_costs, thresholds=[1000, 5000, 10000, 20000, 50000]):
        """Evaluate cost threshold routing across multiple thresholds"""
        results = {}

        for threshold in thresholds:
            predictions, actual_labels = self.cost_threshold_routing(mysql_costs, shannonbase_costs, threshold)

            # Calculate metrics
            accuracy = accuracy_score(actual_labels, predictions)
            precision = precision_score(actual_labels, predictions, zero_division=0)
            recall = recall_score(actual_labels, predictions, zero_division=0)
            f1 = f1_score(actual_labels, predictions, zero_division=0)

            # Calculate confusion matrix
            cm = confusion_matrix(actual_labels, predictions)
            tn, fp, fn, tp = cm.ravel()

            results[threshold] = {
                'accuracy': accuracy,
                'precision': precision,
                'recall': recall,
                'f1': f1,
                'true_positives': int(tp),
                'true_negatives': int(tn),
                'false_positives': int(fp),
                'false_negatives': int(fn),
                'confusion_matrix': cm.tolist()
            }

            self.logger.info(f"\n=== Cost Threshold {threshold} Routing ===")
            self.logger.info(f"  Accuracy: {accuracy:.4f}")
            self.logger.info(f"  Precision: {precision:.4f}")
            self.logger.info(f"  Recall: {recall:.4f}")
            self.logger.info(f"  F1-Score: {f1:.4f}")
            self.logger.info(f"  Confusion Matrix: TP={tp}, TN={tn}, FP={fp}, FN={fn}")

            # Plot confusion matrix for this threshold
            self.plot_confusion_matrix(cm, f'Cost Threshold {threshold}',
                                     self.output_dir / f'confusion_matrix_cost_{threshold}.png')

        return results

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
        """Perform cross-validation with better handling of small datasets"""
        kf = KFold(n_splits=n_folds, shuffle=True, random_state=42)
        cv_scores = []
        cv_metrics = []

        for fold, (train_idx, val_idx) in enumerate(kf.split(X)):
            X_train, X_val = X[train_idx], X[val_idx]
            y_train, y_val = y[train_idx], y[val_idx]

            self.logger.info(f"Fold {fold+1}: Train={len(X_train)}, Val={len(X_val)}")
            self.logger.info(f"Fold {fold+1} class dist: Train={np.bincount(y_train)}, Val={np.bincount(y_val)}")

            # Skip folds with insufficient class diversity
            if len(np.unique(y_val)) < 2:
                self.logger.warning(f"Fold {fold+1} skipped: insufficient class diversity")
                continue

            # Train model with same parameters as main training
            train_data = lgb.Dataset(X_train, label=y_train)
            val_data = lgb.Dataset(X_val, label=y_val, reference=train_data)

            # Use same parameters as main training
            params = {
                'objective': 'binary',
                'metric': 'auc',
                'boosting_type': 'gbdt',
                'num_leaves': 7,
                'learning_rate': 0.1,
                'feature_fraction': 1.0,
                'bagging_fraction': 1.0,
                'min_data_in_leaf': 1,
                'min_data_in_bin': 1,
                'verbose': -1,
                'random_state': 42
            }

            model = lgb.train(
                params,
                train_data,
                num_boost_round=100,
                valid_sets=[val_data],
                callbacks=[lgb.early_stopping(10, verbose=False), lgb.log_evaluation(0)]
            )

            # Evaluate
            y_pred_proba = model.predict(X_val, num_iteration=model.best_iteration)
            y_pred = (y_pred_proba >= 0.5).astype(int)

            # Calculate multiple metrics
            auc_score = roc_auc_score(y_val, y_pred_proba)
            accuracy = accuracy_score(y_val, y_pred)
            precision = precision_score(y_val, y_pred, zero_division=0)
            recall = recall_score(y_val, y_pred, zero_division=0)
            f1 = f1_score(y_val, y_pred, zero_division=0)

            cv_scores.append(auc_score)
            cv_metrics.append({
                'auc': auc_score,
                'accuracy': accuracy,
                'precision': precision,
                'recall': recall,
                'f1': f1
            })

            self.logger.info(f"Fold {fold+1} - AUC: {auc_score:.4f}, Accuracy: {accuracy:.4f}, F1: {f1:.4f}")

        if cv_scores:
            self.logger.info(f"Mean CV AUC: {np.mean(cv_scores):.4f} (+/- {np.std(cv_scores):.4f})")

            # Calculate mean of all metrics
            mean_metrics = {
                metric: np.mean([fold[metric] for fold in cv_metrics if not np.isnan(fold[metric])])
                for metric in ['auc', 'accuracy', 'precision', 'recall', 'f1']
            }

            self.logger.info("Mean CV Metrics:")
            for metric, value in mean_metrics.items():
                if not np.isnan(value):
                    self.logger.info(f"  {metric}: {value:.4f}")
        else:
            self.logger.warning("No valid CV folds completed")

        return cv_scores

    def cross_validate_ensemble(self, X, y, n_folds=5):
        """Perform cross-validation on ensemble models"""
        self.logger.info(f"Performing {n_folds}-fold cross-validation on ensemble...")

        kf = KFold(n_splits=n_folds, shuffle=True, random_state=42)
        cv_scores = []

        for fold, (train_idx, val_idx) in enumerate(kf.split(X)):
            self.logger.info(f"Fold {fold + 1}/{n_folds}")

            X_train_fold, X_val_fold = X[train_idx], X[val_idx]
            y_train_fold, y_val_fold = y[train_idx], y[val_idx]

            try:
                # Train ensemble on this fold
                models = self.train_ensemble(X_train_fold, y_train_fold, X_val_fold, y_val_fold)

                # Evaluate ensemble
                metrics, _ = self.evaluate_ensemble(models, X_val_fold, y_val_fold, f'Fold {fold + 1}')
                cv_scores.append(metrics['f1'])

                self.logger.info(f"Fold {fold + 1} F1: {metrics['f1']:.4f}")

            except Exception as e:
                self.logger.warning(f"Fold {fold + 1} failed: {str(e)}")
                continue

        if cv_scores:
            self.logger.info(f"Cross-validation F1 scores: {cv_scores}")
            self.logger.info(f"Mean F1: {np.mean(cv_scores):.4f} (+/- {np.std(cv_scores):.4f})")
        else:
            self.logger.warning("No valid CV folds completed for ensemble")

        return cv_scores

    def save_ensemble(self, models, model_name):
        """Save ensemble of models"""
        ensemble_dir = self.output_dir / f"{model_name}_ensemble"
        ensemble_dir.mkdir(parents=True, exist_ok=True)

        # Save each model in the ensemble
        for i, model in enumerate(models):
            model_path = ensemble_dir / f"model_{i}.txt"
            model.save_model(str(model_path))
            self.logger.info(f"Saved ensemble model {i} to {model_path}")

        # Save ensemble metadata
        metadata = {
            'n_models': len(models),
            'model_type': 'lightgbm_ensemble',
            'feature_count': models[0].num_feature(),
            'created_at': pd.Timestamp.now().isoformat()
        }

        metadata_path = ensemble_dir / 'ensemble_metadata.json'
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)

        self.logger.info(f"Saved ensemble metadata to {metadata_path}")

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

    def run_training_pipeline(self, use_feature_selection=True, top_n_features=32):
        """Run complete training pipeline"""
        # Process results files
        df = self.process_results_files()

        if df is None or len(df) == 0:
            self.logger.error("No training data available!")
            return None

        # Save dataset to CSV for compatibility
        dataset_path = self.output_dir / 'lightgbm_dataset.csv'
        self.save_dataset(df, dataset_path)

        # Prepare datasets
        X_train, X_val, X_test, y_train, y_val, y_test = self.prepare_datasets(df)

        # Extract costs for cost threshold comparison
        mysql_costs_test = df.loc[df.index[df.index.isin(range(len(X_train), len(X_train) + len(X_test)))], 'row_latency'].values
        shannonbase_costs_test = df.loc[df.index[df.index.isin(range(len(X_train), len(X_train) + len(X_test)))], 'col_latency'].values

        # Evaluate cost threshold routing
        self.logger.info("\n=== Evaluating Original Cost Threshold Routing ===")
        cost_threshold_results = self.evaluate_cost_threshold(mysql_costs_test, shannonbase_costs_test)

        # Find best cost threshold
        best_threshold = max(cost_threshold_results.keys(),
                           key=lambda k: cost_threshold_results[k]['f1'])
        best_cost_metrics = cost_threshold_results[best_threshold]

        self.logger.info(f"\n=== Best Cost Threshold: {best_threshold} ===")
        self.logger.info(f"  F1-Score: {best_cost_metrics['f1']:.4f}")

        if use_feature_selection:
            # Train with feature selection
            self.logger.info(f"\n=== Training with feature selection (top {top_n_features} features) ===")

            # Step 1: Train ensemble on all features to get importance
            self.logger.info("Step 1: Training ensemble on all features to determine importance...")
            full_models = self.train_ensemble(X_train, y_train, X_val, y_val)

            # Use first model for importance analysis (they should be similar)
            full_model = full_models[0]

            # Step 2: Analyze feature importance
            importance_df, top_indices = self.analyze_feature_importance(full_model, top_n_features)

            # Step 3: Retrain on selected features
            self.logger.info(f"Step 2: Retraining on top {len(top_indices)} features...")
            X_train_selected = X_train[:, top_indices]
            X_val_selected = X_val[:, top_indices]
            X_test_selected = X_test[:, top_indices]

            selected_models = self.train_ensemble(X_train_selected, y_train, X_val_selected, y_val)

            # Evaluate ensemble models
            self.logger.info("\n=== Full Ensemble Evaluation (all features) ===")
            full_metrics, full_cm = self.evaluate_ensemble(full_models, X_test, y_test, 'LightGBM Ensemble (All Features)')
            self.plot_confusion_matrix(full_cm, 'LightGBM Ensemble (All Features)',
                                     self.output_dir / 'confusion_matrix_lightgbm_full.png')

            self.logger.info(f"\n=== Selected Ensemble Evaluation ({len(top_indices)} features) ===")
            selected_metrics, selected_cm = self.evaluate_ensemble(selected_models, X_test_selected, y_test, 'LightGBM Ensemble (Selected Features)')
            self.plot_confusion_matrix(selected_cm, 'LightGBM (Selected Features)',
                                     self.output_dir / 'confusion_matrix_lightgbm_selected.png')

            # Compare performance
            self.logger.info("\n=== Performance Comparison ===")
            self.logger.info(f"Full model AUC: {full_metrics['auc']:.4f}")
            self.logger.info(f"Selected model AUC: {selected_metrics['auc']:.4f}")
            self.logger.info(f"Feature reduction: {X_train.shape[1]} -> {len(top_indices)}")

            # Compare with best cost threshold
            self.logger.info(f"\n=== LightGBM vs Cost Threshold Comparison ===")
            self.logger.info(f"Best Cost Threshold ({best_threshold}) F1: {best_cost_metrics['f1']:.4f}")
            self.logger.info(f"LightGBM Selected F1: {selected_metrics['f1']:.4f}")
            self.logger.info(f"LightGBM improvement: {(selected_metrics['f1'] - best_cost_metrics['f1']):.4f}")

            # Print comprehensive metrics table
            self.print_metrics_table(full_metrics, cost_threshold_results, best_threshold)

            # Save selected model and indices
            self.save_ensemble(selected_models, 'hybrid_optimizer_selected')
            self.save_ensemble(full_models, 'hybrid_optimizer_full')

            final_models = selected_models
            final_metrics = selected_metrics

        else:
            # Train without feature selection (baseline) - use ensemble
            self.logger.info("\n=== Training ensemble without feature selection (all features) ===")
            models = self.train_ensemble(X_train, y_train, X_val, y_val)

            # Evaluate ensemble
            self.logger.info("\nEvaluating ensemble on test set:")
            metrics, cm = self.evaluate_ensemble(models, X_test, y_test, 'LightGBM Ensemble (All Features)')
            self.plot_confusion_matrix(cm, 'LightGBM Ensemble (All Features)',
                                     self.output_dir / 'confusion_matrix_lightgbm_baseline.png')

            # Compare with best cost threshold
            self.logger.info(f"\n=== LightGBM vs Cost Threshold Comparison ===")
            self.logger.info(f"Best Cost Threshold ({best_threshold}) F1: {best_cost_metrics['f1']:.4f}")
            self.logger.info(f"LightGBM F1: {metrics['f1']:.4f}")
            self.logger.info(f"LightGBM improvement: {(metrics['f1'] - best_cost_metrics['f1']):.4f}")

            # Print comprehensive metrics table
            self.print_metrics_table(metrics, cost_threshold_results, best_threshold)

            # Analyze feature importance
            self.logger.info("\nAnalyzing feature importance:")
            importance_df, top_indices = self.analyze_feature_importance(model, top_n_features)

            # Save ensemble models
            self.save_ensemble(models, 'hybrid_optimizer_ensemble')

            final_models = models
            final_metrics = metrics

        # Cross-validation on final ensemble
        self.logger.info("\nPerforming 5-fold cross-validation on final ensemble...")
        cv_scores = self.cross_validate_ensemble(X_train, y_train)

        # Save final ensemble
        self.save_ensemble(final_models, 'hybrid_optimizer_final')

        # Save final metrics
        metrics_summary = {
            'total_samples': len(df),
            'feature_count': X_train.shape[1],
            'test_metrics': final_metrics,
            'confusion_matrix': final_metrics.get('confusion_matrix', []) if 'confusion_matrix' in final_metrics else [],
            'cost_threshold_comparison': {
                'best_threshold': best_threshold,
                'best_cost_metrics': best_cost_metrics,
                'all_threshold_results': cost_threshold_results,
                'lightgbm_vs_cost_improvement': final_metrics['f1'] - best_cost_metrics['f1']
            },
            'cv_scores': cv_scores,
            'cv_mean': float(np.mean(cv_scores)),
            'cv_std': float(np.std(cv_scores))
        }

        if use_feature_selection:
            metrics_summary['feature_selection'] = {
                'original_features': X_train.shape[1],
                'selected_features': len(top_indices),
                'selected_indices': top_indices.tolist()
            }

        # Save final metrics
        metrics_path = self.output_dir / 'training_metrics.json'
        with open(metrics_path, 'w') as f:
            json.dump(metrics_summary, f, indent=2)

        self.logger.info(f"\nTraining complete! Results saved to {self.output_dir}")
        self.logger.info(f"Training metrics saved to {metrics_path}")

        return final_models, metrics_summary


def main():
    parser = argparse.ArgumentParser(
        description='Train LightGBM model from JSON results files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Train with feature selection
  python3 train_lightgbm_model_updated.py --data ./training_data

  # Train without feature selection (all features)
  python3 train_lightgbm_model_updated.py --data ./training_data --no-feature-selection

  # Train with custom feature count
  python3 train_lightgbm_model_updated.py --data ./training_data --top-n 64

  # Specify output directory
  python3 train_lightgbm_model_updated.py --data ./training_data --output ./my_models
        """)
    parser.add_argument('--data', type=str, default='../training_data',
                       help='Path to directory containing q_*_results.json files')
    parser.add_argument('--output', type=str, default='./models',
                       help='Output directory for trained models (default: ./models)')
    parser.add_argument('--no-feature-selection', action='store_true',
                       help='Train without feature selection (use all features)')
    parser.add_argument('--top-n', type=int, default=32,
                       help='Number of top features to select (default: 32)')

    args = parser.parse_args()

    trainer = LightGBMTrainerUpdated(args.data, args.output)

    use_feature_selection = not args.no_feature_selection
    trainer.run_training_pipeline(
        use_feature_selection=use_feature_selection,
        top_n_features=args.top_n
    )


if __name__ == "__main__":
    main()