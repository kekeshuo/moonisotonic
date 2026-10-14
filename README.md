# MoonIsotonic

纯 MoonBit 的加权保序回归与可解释单调校准库。输入带权观测，输出满足递增或递减约束的拟合块和可移植经验模型；不依赖 Python、FFI 或第三方数值运行时。

模块：`kekeshuo/moonisotonic@0.1.0`。许可证：MIT。项目是原创实现，不是 SciPy 或 scikit-learn 的逐行移植。

## 安装与最小使用

在自己的 MoonBit 模块中执行：

```sh
moon add kekeshuo/moonisotonic@0.1.0
```

在调用包的 `moon.pkg` 中添加：

```moonbit
import {
  "kekeshuo/moonisotonic" @iso,
}
```

```moonbit
let fit = @iso.fit_l2([3.0, 1.0, 2.0], [1.0, 1.0, 1.0]).unwrap()
// fit.values == [2.0, 2.0, 2.0]; 块采用 [start, end) 下标。
let model = @iso.train_l2([
  @iso.sample(0.0, 0.0),
  @iso.sample(2.0, 4.0),
]).unwrap()
let prediction = @iso.predict(model, 1.0).unwrap() // 2.0
let saved = @iso.encode_model(model).unwrap()
let restored = @iso.decode_model(saved).unwrap()
```

示例中的 `unwrap()` 只用于已知有效数据；生产调用应匹配 `Ok` / `Err`。完整公开接口见 `pkg.generated.mbti`，字段均有明确类型。

## 能力与接口

| 工作流 | 主要入口 | 结果/约定 |
|---|---|---|
| 有序数组拟合 | `isotonic`, `fit_l2`, `fit_l1`, `fit_quantile` | 权重严格为正，双方向，块与目标值 |
| 带约束拟合 | `fit_bounded`, `fit_range`, `check_bounds` | 逐点有限闭区间，拒绝不可行链 |
| 训练经验曲线 | `prepare`, `train_l2`, `train_l1`, `train_quantile` | 稳定按坐标排序，重复坐标共享预测 |
| 查询/移植 | `predict`, `predict_many`, `inverse`, `threshold_domain`, JSON codec | 三种插值、三种边界策略、平台逆区间 |
| 解释/导出 | `audit_order`, `audit_projection`, `explain_fit`, TSV | 原行恢复、违反定位、残差与块解释 |
| 下游评估 | `evaluate`, `reliability`, `holdout`, `cross_validate` | 加权误差、Brier/ECE、显式分区 |
| 描述不确定性 | `train_band`, `band_coverage`, `resample_sensitivity` | 不交叉经验分位数包络、调用者提供重采样计划 |

`weighted_quantile` 采用下侧加权分位数：累计权重首次达到 tau×总权重的观测，tau 允许 0/1；拟合的 tau 必须严格在 (0,1)。L1 目标是加权绝对误差，不是其一半；quantile 目标为加权 pinball loss。

## 三个可运行下游场景

1. **模型服务开发者**：概率分数与标签按显式行索引划分训练/留出集，训练单调映射，对留出集比较 Brier/ECE，并保存 JSON 模型。留出误差不保证改善。
   `moon run examples/probability`
2. **仪表与传感器系统**：将噪声递减标定点训练为递减曲线，查询读数与整个平台的逆区间，经 JSON 往返后验证预测一致。
   `moon run examples/instrument`
3. **数据分析工具**：读取 x/y/weight 数值 TSV，拟合 L1 曲线和分位数包络，导出预测/残差与块解释，通过显式 fold IDs 生成 out-of-fold 预测。
   `moon run examples/analysis`

每个例子都包含输入、处理、结果断言，断言失败会退出。所有数据是仓库内人工合成夹具，无外部数据许可证或隐私数据。

## 验证与兼容

已测开发工具链：`moonc v0.10.14+7d59c7ec9-dev` / `moon 0.1.20260920`。CI 固定官方该版本二进制和匹配 core，四目标均运行严格检查、构建、测试与三个示例。

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn --target wasm-gc
moon test --deny-warn --target wasm-gc
moon build --deny-warn --target wasm-gc
moon run examples/probability --deny-warn --target wasm-gc
# 将目标替换为 wasm、js、native 重复；native 需要 C 编译器。
```

25 个测试声明包含 726 个 L2、2178 个 quantile、1638 个带界拟合独立穷举检查（不是 4542 个独立测试声明），另含黑盒 API、非法输入、变换性质、分区、编码和集成断言。没有性能优越性或统计有效性基准声明。`docs/architecture.md` 说明测试 oracle 与模型边界。

## 复杂度与限制

- 链 L2 PAVA 与有限逐点 bounds 拟合：O(n) 时间、O(n) 空间。数据准备稳定排序 O(n log n)。
- generalized PAVA 反复重排合并块，保守最坏 O(n² log n)；不是线性 quantile 求解器。重复坐标分位数保留原始观测，不用均值替代。
- 单次预测先 O(k) 验证模型再 O(log k) 查找；批量一次验证，O(k + q log k)。逆查询 O(k)。
- 使用 Double，不处理任意精度或极端动态范围。非有限输入、总权重或目标溢出返回 Err；未提供区间算术或误差证书。
- 默认线性插值和域外 Clamp；Previous/Next 和 Reject/Extend 显式选择。inverse 仅针对线性插值与训练域，返回闭区间，不逆推域外延长线。
- JSON 是 `moonisotonic/1` 版本化数组 schema，不是其他框架的模型格式；模型/TSV 文本限制 16000000 UTF-16 code units。JSON 使用 core parser 的默认嵌套深度，另有限 knot 预算。
- 模型公开数组可变；预测/编码入口重新验证，`copy_model` 隔离数组。错误是 String，不是稳定的机器错误码协议。
- 固定宽度 ECE 依赖 bin_count；经验 quantile 包络和重采样敏感性**不是置信区间**。没有隐式随机拆分；行索引隔离不能保证没有实体、时间或特征泄漏。连续 fold 的训练仍包含其他所有 folds，不等于滚动回测。
- 不实现一般 QP、任意偏序/DAG、多维保序、训练基模型、全统计工具箱、一般 CSV、CLI 文件管理、绘图、网络服务或 scikit-learn 全 API。

## 项目文档

- `docs/architecture.md`：算法、模型、数值契约与验证方式
- `docs/security.md`：不可信输入、预算与部署边界
- `docs/competition/duplicate-check.md`：有界生态核查与相邻方案差异
- `REFERENCES.md`、`AI-USE.md`：算法参考、原创与 AI 使用边界
- `CHANGELOG.md`：版本变更

比赛申报文件不属于公开源码或发布包。发布物只有库、测试、示例及去秘密的工程文档。
