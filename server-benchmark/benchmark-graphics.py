import matplotlib.pyplot as plt
import numpy as np

# Data
languages = ['Elixir', 'Go', 'Rust']
valid_json = [26914.27, 84992.42, 43642.00]
invalid_json = [25248.97, 91971.88, 44999.01]

# Set up the figure and axis
plt.figure(figsize=(10, 6))
bar_width = 0.35
index = np.arange(len(languages))

# Create bars
plt.bar(index, valid_json, bar_width, label='JSON válido', color='skyblue')
plt.bar(index + bar_width, invalid_json, bar_width, label='JSON Inválido', color='steelblue')

# Customize the chart
plt.xlabel('Lenguaje')
plt.ylabel('Solicitudes por segundo')
plt.title('Solicitudes por segundo según Lenguaje')
plt.xticks(index + bar_width / 2, languages)
plt.legend()
plt.grid(True, axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()

# Save the plot
plt.savefig('requests_per_second.png')