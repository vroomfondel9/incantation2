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
