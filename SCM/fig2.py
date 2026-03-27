import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# ==================== 1. 读取数据 ====================
# 方法A：读取dta文件（推荐）
df = pd.read_stata(r'temp_synth_results.dta')
df["gap"] = -df["y_synth"] + df["y_real"]

# ==================== 绘图 ====================
fig, ax = plt.subplots(figsize=(20, 12))

# 1. 生成原始颜色
colors = plt.cm.hsv(np.linspace(0, 1, 50))
import matplotlib.colors as mcolors
# --- 修改开始：降低亮度 ---
# 将 RGB 转换为 HSV
hsv_colors = mcolors.rgb_to_hsv(colors[:, :3])

# 降低 V (亮度) 分量。
# 0.0 是纯黑，1.0 是原色。这里乘以 0.5 让颜色变暗一半。
# 你也可以尝试 0.6 或 0.7，看你喜欢多暗。
hsv_colors[:, 2] = hsv_colors[:, 2] * 0.5

# 将 HSV 转回 RGB
colors_dark = mcolors.hsv_to_rgb(hsv_colors)

# 补回 Alpha 通道 (透明度)，因为上面只处理了 RGB
colors_dark = np.column_stack((colors_dark, colors[:, 3]))

colors = colors_dark
states_sorted = sorted(df['state_id'].unique())

# 绘制每个州的折线
for idx, state in enumerate(states_sorted):
    state_data = df[df['state_id'] == state].sort_values('year')

    # State_50加粗标黑
    if state == 48:
        ax.plot(state_data['year'], state_data['gap'],
                label=state, color='black', linewidth=4,  # 黑色加粗
                alpha=1, marker='o', markersize=6, zorder=10)  # zorder置顶
    else:
        ax.plot(state_data['year'], state_data['gap'],
                label=state, color=colors[idx], linewidth=2,
                alpha=0.7, marker='o', markersize=3)

# 添加红色竖线（1998和2004）
ax.axvline(x=1998, color='red', linestyle='--', linewidth=2, alpha=0.8, label='Year 1998')
ax.axvline(x=2004, color='red', linestyle='--', linewidth=2, alpha=0.8, label='Year 2004')

# 美化
# ax.set_title(' by State Over Time (State_50 Highlighted)',
#              fontsize=20, fontweight='bold', pad=20)
ax.set_xlabel('Year', fontsize=16, fontweight='bold')
ax.set_ylabel('Gap Value', fontsize=16, fontweight='bold')
ax.grid(True, alpha=0.3, linestyle='--')

# 图例
handles, labels = ax.get_legend_handles_labels()
# 把State_50和竖线放前面
ax.legend(handles, labels, bbox_to_anchor=(1.02, 1), loc='upper left',
          ncol=2, fontsize=9, frameon=True)

plt.tight_layout()
output_path = 'gap_by_state_highlight.png'
plt.savefig(output_path, dpi=300, bbox_inches='tight', facecolor='white')
print(f"图表已保存: {output_path}")
plt.show()
plt.show()