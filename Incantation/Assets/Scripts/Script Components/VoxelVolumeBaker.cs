using System;
using UnityEngine;

[ExecuteAlways]
public class VoxelVolumeBaker : MonoBehaviour
{
    [Tooltip("MagicaVoxel stacked PNG. Must end with _h#.png")]
    public Texture sourceTexture;

    [HideInInspector]
    public Material editorMaterial;

    [HideInInspector]
    public String originalVoxelTextureId;

    [HideInInspector]
    public Boolean modified;

    void OnDisable()
    {
        if (Application.isPlaying)
        {
            Renderer _renderer = GetComponent<Renderer>();
            _renderer.sharedMaterial = editorMaterial;
        }
    }

}
