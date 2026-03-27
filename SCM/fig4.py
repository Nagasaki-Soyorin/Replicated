import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os


# 读取数据
dta_files = ["Fig_energystate.dta","Fig_noDminwage.dta","Fig_stateitc.dta","Fig_DwelfareQ34.dta"]
dta_name = [dta[:-4] for dta in dta_files]


path = []
for dta in dta_files:
    df = pd.read_stata(os.path.join("Data_file",dta))
    df["name"] = dta[:-4]
    path.append(df)

# 数据来源是什么

data = pd.DataFrame()
for df in path:
    data = pd.concat([data, df])


data["gap"] = data["_Y_treated"] - data["_Y_synthetic"]




data.rename(columns={"name":"state_id",
                     "_time":"year"}, inplace=True)


fig, ax = plt.subplots(figsize=(12, 8))
cmap = plt.get_cmap('tab20')

# 生成 50 个颜色。
# 注意：tab20 只有 20 个基础色，这里通过取模 (%) 循环使用，保证前 20 个和后 20 个颜色不重复
states_count = 50
colors = [cmap(i % 20) for i in range(states_count)]
# 绘制每个州的折线
for idx, state in enumerate(dta_name):
    state_data = data[data['state_id'] == state].sort_values('year')

    # State_50加粗标黑
    if state == 48:
        ax.plot(state_data['year'], state_data['gap'],
                label=state, color='black', linewidth=4,  # 黑色加粗
                alpha=1, marker='o', markersize=6, zorder=10)  # zorder置顶
    else:
        ax.plot(state_data['year'], state_data['gap'],
                label=state[4:], color=colors[idx], linewidth=2,
                alpha=0.7, marker='o', markersize=3)
# ... (前面的绘图代码保持不变) ...

# 添加红色竖线（1998和2004）
ax.axvline(x=1998, color='red', linestyle='--', linewidth=2, alpha=0.8, label='Year 1998')
ax.axvline(x=2004, color='red', linestyle='--', linewidth=2, alpha=0.8, label='Year 2004')

# --- 新增：添加 y=0 的水平虚线 ---
ax.axhline(y=0, color='darkred', linestyle='--', linewidth=1.5, alpha=0.9, label='Zero Line')

# 美化
ax.set_xlabel('Year', fontsize=16, fontweight='bold')
ax.set_ylabel('Gap Value', fontsize=16, fontweight='bold')
ax.grid(True, alpha=0.3, linestyle='--')

# 图例设置
handles, labels = ax.get_legend_handles_labels()

# 修改位置：左上角 (0, 1)
# 允许重叠：设置 framealpha < 1.0 可以让图例背景半透明，从而看到后面的线条
ax.legend(handles, labels,
          bbox_to_anchor=(1, 1),  # 左上角坐标 (x, y)
          loc='upper right',       # 锚点在左上
          ncol=2,
          fontsize=9,
          frameon=True,           # 显示边框
          facecolor='white',      # 背景色
          framealpha=0.8)         # 透明度 (0.8表示80%不透明，线条可透过)

plt.tight_layout()

# 注意：tight_layout 有时会裁剪掉位于边缘的图例。
# 如果发现图例被切掉，可以在 savefig 中再次强调 bbox_inches
output_path = 'gap_by_state_highlight.png'
plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
plt.show()
print(f"图表已保存: {output_path}")

print("done")







