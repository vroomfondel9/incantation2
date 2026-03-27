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
  <img src="https://i.giphy.com/p3X0K13VfI2RhkqK1d.gif" width="45%" />
  <img src="https://i.giphy.com/Rj2siRK3zlxC0bKSaB.gif" width="45%" />
</p>

### Collision Detection
<p align="center">
  <img src="https://i.giphy.com/U3GuGz8ZPoOfAyRzCS.gif" width="80%" />
</p>

### Fluid Simulation Optimizations
<p align="center">
  <img src="https://i.giphy.com/A0gRIMpKZq4qRiuuS2.gif" width="80%" />
</p>
