#include "sql/hybrid_opt/feature_extractor.h"
#include <cmath>
#include <algorithm>
#include <cstdio>
#include "sql/sql_class.h"
#include "sql/sql_executor.h"
#include "sql/range_optimizer/range_optimizer.h"
#include "sql/handler.h"
#include "sql/item_subselect.h"

namespace hybrid_opt {

bool FeatureExtractor::ExtractFeatures(const JOIN *join,
                                       std::array<float, NUM_FEATURES> &features,
                                       Opt_trace_context *trace) {
  if (!join) return false;
  
  // Initialize all features to 0
  features.fill(0.0f);
  int idx = 0;
  
  // Extract different categories of features
  ExtractTableFeatures(join, features.data(), idx);
  ExtractJoinFeatures(join, features.data(), idx);
  ExtractPredicateFeatures(join, features.data(), idx);
  ExtractAggregationFeatures(join, features.data(), idx);
  ExtractOrderingFeatures(join, features.data(), idx);
  ExtractCostFeatures(join, features.data(), idx);
  
  // Add to trace if enabled
  if (trace && trace->is_started()) {
    AddToOptimizerTrace(trace, features.data(), NUM_FEATURES);
  }
  
  return idx > 0;
}

bool FeatureExtractor::ExtractSelectedFeatures(const JOIN *join,
                                               const std::vector<int> &feature_indices,
                                               std::vector<float> &selected_features,
                                               Opt_trace_context *trace) {
  std::array<float, NUM_FEATURES> all_features;
  
  if (!ExtractFeatures(join, all_features, nullptr)) {
    return false;
  }
  
  // Select features based on provided indices
  selected_features.clear();
  selected_features.reserve(feature_indices.size());
  for (int idx : feature_indices) {
    if (idx >= 0 && idx < NUM_FEATURES) {
      selected_features.push_back(all_features[idx]);
    }
  }
  
  // Add to trace if enabled
  if (trace && trace->is_started()) {
    Opt_trace_object feat_node(trace, "hybrid_optimizer_selected_features");
    feat_node.add("num_selected", static_cast<int>(selected_features.size()));
    
    Opt_trace_array feat_array(trace, "features");
    for (size_t i = 0; i < selected_features.size(); ++i) {
      Opt_trace_object feat_item(trace);
      feat_item.add("index", feature_indices[i]);
      feat_item.add("value", selected_features[i]);
      static std::vector<std::string> feature_names = GetFeatureNames();
      if (feature_indices[i] < static_cast<int>(feature_names.size())) {
        feat_item.add_alnum("name", feature_names[feature_indices[i]].c_str());
      }
    }
  }
  
  return true;
}

std::vector<int> FeatureExtractor::LoadFeatureIndices(const std::string &filename) {
  std::vector<int> indices;
  
  // Simple file format: one index per line
  FILE *file = fopen(filename.c_str(), "r");
  if (!file) {
    // Fall back to default top indices if file not found
    // These will be replaced by actual importance-based indices after training
    for (int i = 0; i < DEFAULT_TOP_FEATURES; ++i) {
      indices.push_back(i);
    }
    return indices;
  }
  
  int idx;
  while (fscanf(file, "%d\n", &idx) == 1) {
    indices.push_back(idx);
  }
  fclose(file);
  
  return indices;
}

void FeatureExtractor::ExtractTableFeatures(const JOIN *join,
                                           float *features,
                                           int &idx) {
  // Aggregators for statistics
  double total_rows = 0;
  double max_rows = 0;
  double min_rows = 1e30;
  int table_count = 0;
  int const_table_count = 0;
  int fullscan_count = 0;
  int index_scan_count = 0;
  
  // Scan all tables
  for (uint i = join->const_tables; i < join->primary_tables; ++i) {
    const QEP_TAB *tab = &join->qep_tab[i];
    const POSITION *pos = tab->position();
    if (!pos) continue;
    
    TABLE *table = tab->table();
    if (!table) continue;
    
    table_count++;
    
    // Row count features
    double rows = pos->prefix_rowcount;
    total_rows += rows;
    max_rows = std::max(max_rows, rows);
    min_rows = std::min(min_rows, rows);
    
    // Access type features
    switch (tab->type()) {
      case JT_ALL:
        fullscan_count++;
        break;
      case JT_INDEX_SCAN:
      case JT_RANGE:
      case JT_REF:
      case JT_EQ_REF:
        index_scan_count++;
        break;
      case JT_CONST:
      case JT_SYSTEM:
        const_table_count++;
        break;
      default:
        break;
    }
  }
  
  // Store features
  features[idx++] = static_cast<float>(table_count);                    // 0
  features[idx++] = static_cast<float>(LogTransform(total_rows));       // 1
  features[idx++] = static_cast<float>(LogTransform(max_rows));         // 2
  features[idx++] = static_cast<float>(LogTransform(min_rows));         // 3
  features[idx++] = static_cast<float>(const_table_count);              // 4
  features[idx++] = static_cast<float>(fullscan_count);                 // 5
  features[idx++] = static_cast<float>(index_scan_count);               // 6
  features[idx++] = static_cast<float>(table_count > 1 ? 1.0 : 0.0);    // 7 - multi-table
  features[idx++] = static_cast<float>(const_table_count == table_count);// 8 - all const
}

void FeatureExtractor::ExtractJoinFeatures(const JOIN *join,
                                          float *features,
                                          int &idx) {
  // Join type counters
  int inner_joins = 0;
  int outer_joins = 0;
  int semi_joins = 0;
  int anti_joins = 0;
  double max_fanout = 1.0;
  double total_join_cost = 0;
  
  for (uint i = join->const_tables; i < join->primary_tables; ++i) {
    const QEP_TAB *tab = &join->qep_tab[i];
    const POSITION *pos = tab->position();
    if (!pos) continue;
    
    // Join type analysis
    if (tab->table_ref && tab->table_ref->outer_join) {
      outer_joins++;
    } else {
      inner_joins++;
    }
    
    // Semi-join detection
    if (pos->sj_strategy != SJ_OPT_NONE) {
      semi_joins++;
    }
    
    // Fanout computation
    if (i > join->const_tables) {
      double fanout = pos->prefix_rowcount / std::max(1.0, pos->prefix_rowcount);
      max_fanout = std::max(max_fanout, fanout);
    }
    
    // Join cost
    total_join_cost += pos->read_cost;
  }
  
  // Store join features
  features[idx++] = static_cast<float>(inner_joins);                    // 9
  features[idx++] = static_cast<float>(outer_joins);                    // 10
  features[idx++] = static_cast<float>(semi_joins);                     // 11
  features[idx++] = static_cast<float>(anti_joins);                     // 12
  features[idx++] = static_cast<float>(LogTransform(max_fanout));       // 13
  features[idx++] = static_cast<float>(LogTransform(total_join_cost));  // 14
  features[idx++] = static_cast<float>(join->primary_tables - join->const_tables - 1); // 15 - join count
}

void FeatureExtractor::ExtractPredicateFeatures(const JOIN *join,
                                               float *features,
                                               int &idx) {
  // Predicate statistics
  int eq_predicates = 0;
  int range_predicates = 0;
  int like_predicates = 0;
  int in_predicates = 0;
  double avg_selectivity = 0;
  double min_selectivity = 1.0;
  int predicate_count = 0;
  
  // Analyze WHERE condition
  Item *where_cond = join->where_cond;
  if (where_cond) {
    // Simple heuristic analysis (would need proper tree traversal in production)
    String str;
    where_cond->print(join->thd, &str, QT_ORDINARY);
    const char *cond_str = str.c_ptr();
    
    // Count predicate types (simplified)
    if (strstr(cond_str, " = ")) eq_predicates++;
    if (strstr(cond_str, " > ") || strstr(cond_str, " < ") || 
        strstr(cond_str, " >= ") || strstr(cond_str, " <= ")) range_predicates++;
    if (strstr(cond_str, " LIKE ") || strstr(cond_str, " like ")) like_predicates++;
    if (strstr(cond_str, " IN (") || strstr(cond_str, " in (")) in_predicates++;
  }
  
  // Per-table predicates
  for (uint i = join->const_tables; i < join->primary_tables; ++i) {
    const QEP_TAB *tab = &join->qep_tab[i];
    const POSITION *pos = tab->position();
    if (!pos) continue;
    
    if (tab->condition()) {
      predicate_count++;
      double selectivity = ComputeSelectivity(tab, pos);
      avg_selectivity += selectivity;
      min_selectivity = std::min(min_selectivity, selectivity);
    }
  }
  
  if (predicate_count > 0) {
    avg_selectivity /= predicate_count;
  }
  
  // Store predicate features
  features[idx++] = static_cast<float>(eq_predicates);                  // 16
  features[idx++] = static_cast<float>(range_predicates);               // 17
  features[idx++] = static_cast<float>(like_predicates);                // 18
  features[idx++] = static_cast<float>(in_predicates);                  // 19
  features[idx++] = static_cast<float>(predicate_count);                // 20
  features[idx++] = static_cast<float>(avg_selectivity);                // 21
  features[idx++] = static_cast<float>(min_selectivity);                // 22
}

void FeatureExtractor::ExtractAggregationFeatures(const JOIN *join,
                                                 float *features,
                                                 int &idx) {
  // Aggregation features
  bool has_groupby = !join->group_list.empty();
  bool has_distinct = join->select_distinct;
  bool has_having = (join->having_cond != nullptr);
  int sum_func_count = join->tmp_table_param.sum_func_count;
  bool has_windows = join->m_windows.elements > 0;
  
  // Store aggregation features
  features[idx++] = has_groupby ? 1.0f : 0.0f;                         // 23
  features[idx++] = has_distinct ? 1.0f : 0.0f;                        // 24
  features[idx++] = has_having ? 1.0f : 0.0f;                          // 25
  features[idx++] = static_cast<float>(sum_func_count);                // 26
  features[idx++] = has_windows ? 1.0f : 0.0f;                         // 27
  features[idx++] = join->tmp_table_param.sum_func_count ? 1.0f : 0.0f;// 28
  features[idx++] = static_cast<float>(LogTransform(join->tmp_table_param.group_length)); // 29
  features[idx++] = static_cast<float>(LogTransform(join->tmp_table_param.group_parts)); // 30
}

void FeatureExtractor::ExtractOrderingFeatures(const JOIN *join,
                                              float *features,
                                              int &idx) {
  // Ordering features
  bool has_orderby = !join->order.empty();
  bool has_limit = (join->query_expression()->select_limit_cnt != HA_POS_ERROR);
  double limit_value = has_limit ? 
    static_cast<double>(join->query_expression()->select_limit_cnt) : 0;
  bool simple_order = join->simple_order;
  bool simple_group = join->simple_group;
  
  // Store ordering features
  features[idx++] = has_orderby ? 1.0f : 0.0f;                         // 31
  features[idx++] = has_limit ? 1.0f : 0.0f;                           // 32
  features[idx++] = static_cast<float>(LogTransform(limit_value));     // 33
  features[idx++] = simple_order ? 1.0f : 0.0f;                        // 34
  features[idx++] = simple_group ? 1.0f : 0.0f;                        // 35
  features[idx++] = join->need_tmp_before_win ? 1.0f : 0.0f;           // 36
  features[idx++] = join->skip_sort_order ? 1.0f : 0.0f;               // 37
}

void FeatureExtractor::ExtractCostFeatures(const JOIN *join,
                                          float *features,
                                          int &idx) {
  // Cost estimation features
  double total_read_cost = 0;
  double total_eval_cost = 0;
  double total_prefix_cost = 0;
  double max_read_cost = 0;
  
  for (uint i = join->const_tables; i < join->primary_tables; ++i) {
    const QEP_TAB *tab = &join->qep_tab[i];
    const POSITION *pos = tab->position();
    if (!pos) continue;
    
    total_read_cost += pos->read_cost;
    total_prefix_cost += pos->prefix_cost;
    max_read_cost = std::max(max_read_cost, pos->read_cost);
  }
  
  // Store cost features
  features[idx++] = static_cast<float>(LogTransform(total_read_cost));  // 38
  features[idx++] = static_cast<float>(LogTransform(total_prefix_cost));// 39
  features[idx++] = static_cast<float>(LogTransform(max_read_cost));    // 40
  features[idx++] = static_cast<float>(LogTransform(join->best_read));  // 41
  features[idx++] = static_cast<float>(LogTransform(join->best_rowcount)); // 42
  
  // Fill remaining features with zeros (up to 140)
  while (idx < NUM_FEATURES) {
    features[idx++] = 0.0f;
  }
}

double FeatureExtractor::ComputeSelectivity(const QEP_TAB *tab, const POSITION *pos) {
  if (!tab || !pos) return 1.0;
  
  TABLE *table = tab->table();
  if (!table) return 1.0;
  
  double table_rows = static_cast<double>(table->file->stats.records);
  if (table_rows <= 0) return 1.0;
  
  double filtered_rows = pos->prefix_rowcount;
  double selectivity = filtered_rows / table_rows;
  
  return std::min(1.0, std::max(0.0, selectivity));
}

double FeatureExtractor::ComputeFanout(const QEP_TAB *tab) {
  const POSITION *pos = tab->position();
  if (!pos || pos->prefix_rowcount <= 0) return 1.0;
  
  // Simplified fanout calculation
  return pos->prefix_rowcount;
}

double FeatureExtractor::ComputeTableCardinality(const TABLE *table) {
  if (!table || !table->file) return 0;
  return static_cast<double>(table->file->stats.records);
}

void FeatureExtractor::AddToOptimizerTrace(Opt_trace_context *trace,
                                          const float *features,
                                          int feature_count) {
  if (!trace || !trace->is_started()) return;
  
  Opt_trace_object feat_node(trace, "hybrid_optimizer_features");
  feat_node.add("feature_count", feature_count);
  
  Opt_trace_array feat_array(trace, "features");
  char key[16];
  for (int i = 0; i < feature_count; ++i) {
    snprintf(key, sizeof(key), "f%d", i);
    Opt_trace_object feat_item(trace);
    feat_item.add("index", i);
    feat_item.add("value", features[i]);
  }
}

} // namespace hybrid_opt
