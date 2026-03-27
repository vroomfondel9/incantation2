# Incantation Game Engine

Game engine prototype that should support destructable, voxel-based environments as well as real-time fluids.

## 🛠️ Features Under Construction
- Voxel objects rendered using volumetric data. Amanatides and Woo algorithm used for fast rendering.
- SPH-based real-time fluid dynamics simulation (Reference implementation from Coding Adventures YouTube channel with my own optimizations such as radix spacial sort and better memory coherence)
- Collision physics that leverage voxel topology to reduce the workload.

## 🗺️ Planned Features
- Memory efficient fully destructable voxel environments
- Fire simulation
- Tools to support fast art asset creation pipeline

## 🛠️ Tech Stack
- Unity Entity Component System (ECS)
- HLSL Shader Model 6.0 (Requires DirectX 12 + DXC compiler)
- Windows Support Only

## 🖼️ Screenshots

### Dynamic Voxel Surface-Only Rendering
<p align="center">
  <img src="https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcDMzczNwaHQyNDRtenFycmU0M3Q2c2tscG54YmJpY2Yyemd5NmkxOSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/p3X0K13VfI2RhkqK1d/giphy.gif" width="45%" />
  <img src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExMW11ZzFoaTVxanIzczEwbmlvd2pqdG5zcWxicThub3FtOTFmc2lyaSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Rj2siRK3zlxC0bKSaB/giphy.gif" width="45%" />
</p>

### Collision Detection
<p align="center">
  <img src="https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExZDlpemljanVmeGlxaDJncWl6YnhqeHZ6MHJubDNpMm1sN25mOGZmcSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/wgG0q7wb58TJfUMuhA/giphy.gif" width="90%" />
</p>

### Fluid Simulation Optimizations
<p align="center">
  <img src="https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExcmFxd2s4MW9tNWF5a3BzN3FkYnNlNzM5emtxNjNsd3VjNTl1OHp1YiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/Kz2MNmh6BzJ4QXrffa/giphy.gif" width="90%" />
</p>
