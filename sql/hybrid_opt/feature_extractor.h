#ifndef SQL_HYBRID_OPT_FEATURE_EXTRACTOR_H_
#define SQL_HYBRID_OPT_FEATURE_EXTRACTOR_H_

#include <array>
#include <vector>
#include <string>
#include "sql/sql_optimizer.h"
#include "sql/table.h"
#include "sql/opt_trace.h"

namespace hybrid_opt {

constexpr int NUM_FEATURES = 140;  // Total features extracted
constexpr int DEFAULT_TOP_FEATURES = 32;  // Default number of top features

// Feature names for documentation and debugging
static std::vector<std::string> GetFeatureNames() {
  std::vector<std::string> names = {
    // Table features (0-8)
    "table_count", "total_rows_log", "max_rows_log", "min_rows_log",
    "const_table_count", "fullscan_count", "index_scan_count", 
    "is_multi_table", "all_const_tables",
    
    // Join features (9-15)
    "inner_joins", "outer_joins", "semi_joins", "anti_joins",
    "max_fanout_log", "total_join_cost_log", "join_count",
    
    // Predicate features (16-22)  
    "eq_predicates", "range_predicates", "like_predicates", "in_predicates",
    "predicate_count", "avg_selectivity", "min_selectivity",
    
    // Aggregation features (23-30)
    "has_groupby", "has_distinct", "has_having", "sum_func_count",
    "has_windows", "has_tmp_table", "group_length_log", "group_parts_log",
    
    // Ordering features (31-37)
    "has_orderby", "has_limit", "limit_value_log", "simple_order",
    "simple_group", "need_tmp", "skip_sort_order",
    
    // Cost features (38-42)
    "total_read_cost_log", "total_prefix_cost_log", "max_read_cost_log",
    "best_read_log", "best_rowcount_log"
  };
  
  // Fill remaining feature names up to 140
  while (names.size() < NUM_FEATURES) {
    names.push_back("f" + std::to_string(names.size()));
  }
  
  return names;
}

/**
 * Extract features from JOIN object for hybrid optimizer
 */
class FeatureExtractor {
 public:
  /**
   * Extract all features from JOIN object
   * @param join The JOIN object to extract features from
   * @param features Output array for features
   * @param trace Optional trace object for debugging
   * @return true if extraction successful
   */
  static bool ExtractFeatures(const JOIN *join, 
                             std::array<float, NUM_FEATURES> &features,
                             Opt_trace_context *trace = nullptr);

  /**
   * Extract selected features based on indices
   * @param join The JOIN object  
   * @param feature_indices Indices of features to extract
   * @param selected_features Output vector for selected features
   * @param trace Optional trace object
   * @return true if extraction successful
   */
  static bool ExtractSelectedFeatures(const JOIN *join,
                                      const std::vector<int> &feature_indices,
                                      std::vector<float> &selected_features,
                                      Opt_trace_context *trace = nullptr);
  
  /**
   * Load feature indices from file (generated during training)
   * @param filename Path to feature indices file
   * @return Vector of selected feature indices
   */
  static std::vector<int> LoadFeatureIndices(const std::string &filename);

  /**
   * Add features to optimizer trace
   * @param trace The trace context
   * @param features Feature array
   * @param feature_count Number of features
   */
  static void AddToOptimizerTrace(Opt_trace_context *trace,
                                  const float *features,
                                  int feature_count);

 private:
  // Helper functions for feature computation
  static double ComputeSelectivity(const QEP_TAB *tab, const POSITION *pos);
  static double ComputeFanout(const QEP_TAB *tab);
  static double ComputeTableCardinality(const TABLE *table);
  static double LogTransform(double val);
  static double LogTanh(double val);
  
  // Feature extraction helpers
  static void ExtractTableFeatures(const JOIN *join, 
                                   float *features, 
                                   int &feature_idx);
  static void ExtractJoinFeatures(const JOIN *join,
                                  float *features,
                                  int &feature_idx);
  static void ExtractPredicateFeatures(const JOIN *join,
                                       float *features, 
                                       int &feature_idx);
  static void ExtractAggregationFeatures(const JOIN *join,
                                         float *features,
                                         int &feature_idx);
  static void ExtractOrderingFeatures(const JOIN *join,
                                      float *features,
                                      int &feature_idx);
  static void ExtractCostFeatures(const JOIN *join,
                                  float *features,
                                  int &feature_idx);
};

// Inline helper functions
inline double FeatureExtractor::LogTransform(double val) {
  return std::log1p(std::max(0.0, val));
}

inline double FeatureExtractor::LogTanh(double val) {
  return std::tanh(LogTransform(val));
}

} // namespace hybrid_opt

#endif // SQL_HYBRID_OPT_FEATURE_EXTRACTOR_H_
