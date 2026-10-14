# 有界语义查重与选题记录

核查日期：2026-10-14。使用 osc2026-guide 的 Project Research Guide，比较三个不同问题域后预留 MoonIsotonic。本记录只声明所列范围内未找到成熟直接替代，不证明绝对唯一。

## 1. 三候选与门禁

评分每项 1–5，依次为生态广度、用户差异、复用、重合风险可控性、深度、可验证性、工期、维护；它是选择判断，不是性能或用户调查数据。硬门禁失败不能被总分抵消。

| 候选 | 指纹/闭环 | 评分 | 门禁与决定 |
|---|---|---|---|
| 树编辑距离工具库 | 有序树输入→编辑代价/脚本→结构比较；AST、XML、配置审查 | 4/4/4/1/4/5/4/4=30 | mizchi/similarity 已有 APTED 和 compute_edit_distance；直接重合，淘汰 |
| R-tree 空间索引 | 几何边界→打包/范围查询→GIS、碰撞、轨迹下游 | 4/4/4/1/4/4/4/4=29 | LING71671/moon_strtree 已有 2D–4D STR 索引；直接重合，淘汰 |
| 保序回归/经验校准 | 带权观测→链 L2/L1/quantile→可移植单调模型、逆平台和留出评估 | 4/5/5/4/5/5/4/4=36 | 通用 QP/参数拟合/已有单调点插值相邻，但不是噪声非单调观测的保序训练闭环；有界通过 |

注册表在实现前全能力筛查，详细读取通用 QP 已重复的 MoonQP 拒绝纠正记录，不能仅更换 QP 算法重新参赛。2026-10-14 在排他锁内原子追加 MoonIsotonic reserved；不会覆盖其他项目预留或旧记录。

## 2. 检索范围与访问证据

- MoonCakes：实际执行 19 组扩词，`moon search ... --limit 100 --json`：tree edit、zhang、tree、diff、rtree、spatial、isotonic、regression、ordered tree、forest distance、pava、monotonic regression、calibration、least squares、quantile、shape constrained、isotone、保序、monotone。交付前追加 pool adjacent、monotonic calibration、isotonic_regression，共 22 组。
- GitHub：isotonic/PAVA/calibration/rtree/tree edit 加 language:MoonBit 的仓库检索，上限 100；官方 [awesome-moonbit](https://github.com/moonbitlang/awesome-moonbit) 清单。另读 GitHub 相邻项目目录树、源码和测试，不依据名称直接判定。
- 反向代码检索：PAVA、isotonic、fit_quantile 加 language:MoonBit，上限 100。isotonic/fit_quantile 返回空；PAVA 有 13 个数据/生成代码等路径命中，不能把字符串命中当算法覆盖。代码索引与分词限制可能漏掉实现。
- 公开 MoonCakes 详情页面 curvefit/robust_stats HTTP 200；官方 SciPy、scikit-learn 行为文档 HTTP 200。通过独立研究模块实际下载以下精确版本，阅读 README、源码、公开接口及测试，而非只读搜索摘要。
- 搜索原始 JSON、下载源码、访问记录留在本地私有工程审计目录；公开文档保留可复核链接和具体路径。浏览搜索工具曾无返回；不把空工具输出计作生态无结果证据。错误组织 moonbit-community/awesome-moonbit 返回 404，随后改查官方 moonbitlang 清单。

## 3. 能力矩阵与源码依据

| 项目/版本/链接 | 用户、输入、行为、输出 | 实际源码/接口/测试证据 | 分类与选择边界 |
|---|---|---|---|
| [mizchi/similarity@0.2.2](https://github.com/mizchi/similarity.mbt) | AST/树结构比较，输入树→APTED距离 | 发布 manifest 描述 APTED；公开 compute_edit_distance，树距离源码及测试 | 树候选直接重合，不做 |
| [LING71671/moon_strtree@0.2.1](https://github.com/LING71671/MoonSTRtree) | GIS/轨迹边界→STR打包→范围空间查询 | 发布 README、索引源码、接口及测试；2D/3D/4D capabilities | R-tree 候选直接重合，不做 |
| [Juwan-Hwang/moon-certified@0.1.1](https://github.com/Juwan-Hwang/moon-certified) | 数值工具用户，稠密 QP/KKT 矩阵→一般优化解，线性/logistic regression | 发布 KKT/回归源码和接口；未识别链 PAVA 或经验单调模型训练 | 高度相邻；L2 可转成 QP，所以不以改算法宣称创新。核心非二次分位数、重复坐标经验模型/解释/逆区间工作流独立于稠密 QP |
| [yyyt0807/curvefit@0.2.1](https://github.com/yyyt0807/moonbit-curvefit) | 指定前向模型和参数→残差迭代优化→参数/诊断 | 发布 README、残差/边界优化源码、接口和测试 | 同数值方向不同任务；非参数形状约束训练，不是指定模型参数优化 |
| [hxiuzheng/robust_stats@0.2.2](https://github.com/hxiuzheng/moon-robust-stats) | 稳健统计/分类评估，分数→阈值扫描/Brier/ECE等报告 | calibration_curve 源码为决策阈值扫描，不训练单调预测映射；公开接口和测试 | 相邻评估能力明确重叠，不声称 Brier/ECE 新颖；核心可训练映射不同 |
| [wjyupl/measure@0.1.2](https://github.com/wjyupl/moonbit-measure) | 仪表标定输入→单调点插值/修正，另多项式 QR 拟合 | 发布 src/calibration/calibration.mbt 的 CalibrationCurve::fit 要求 reference 和 observed 严格递增，重复/非单调即 Err；calibration_test.mbt 明确拒绝 NonMonotonicData。polynomial.mbt 是指定阶数 QR，不施加经验链单调约束 | 高度相邻；预测/逆修正/LOO重叠，但不能吸收噪声非单调或递减点、加权池化、L1/quantile。MoonIsotonic 不复制测量不确定性工具箱 |

维护证据限于实际可访问的发布版本/仓库，并非承诺未来维护。检索返回的 downloads、版本和时间是核查日快照，不是质量评分；没有完整生态下载量比较。

## 4. 固定选题与独立建设理由

目标用户是模型服务、仪表经验曲线、数据分析工具。输入为正权重有限 Double，输出是方向单调拟合块、严格坐标 knots、模型 JSON、预测/逆区间与显式留出报告。专用链 PAVA + canonical lower quantile，逐点有限上下界、重复坐标保留原观测的非二次拟合，是训练核心；不是插值已单调数据的外壳，也不是通用 QP 再命名。

独立包避免引入稠密优化矩阵或测量学域类型作为经验模型训练依赖，支持四目标和三个数据域共用同一模型契约。已有指标与插值技术只是工作流辅助，不算创新性依据。明确不做：一般QP、任意偏序、多维保序、基模型训练、全面统计或临床有效性保证。

交付前复核发现 measure 的真实相邻实现后再次阅读公开发布源码和测试，差异仍是核心输入/训练任务而非名称。若以后出现成熟直接替代，应优先讨论合并/合作，而非继续声称唯一。

## 5. 限制

MoonCakes 搜索最多100结果且为语义/模糊检索；GitHub索引有时延、代码搜索分词和上限；清单不涵盖全部项目。只检查可访问源码与注册表，不覆盖私有、未索引、新上传或未发布实现。零结果不构成不重复证明。本结论有日期和范围，不能表述“首个/唯一”。
