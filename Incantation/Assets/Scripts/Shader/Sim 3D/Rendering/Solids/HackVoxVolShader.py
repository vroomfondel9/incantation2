import os
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SHADER_PATH = os.path.join(SCRIPT_DIR, "VoxVolShader.shader")


def main():
    if not os.path.exists(SHADER_PATH):
        print("VoxVolShader.shader not found next to the script.")
        return

    with open(SHADER_PATH, "r", encoding="utf-8") as f:
        text = f.read()

    # ---------------------------------------------------------
    # 1. Fix shader name
    # ---------------------------------------------------------
    text = re.sub(
        r'Shader\s+"Shader Graphs/VoxVolShader[^"]*"',
        'Shader "Shader Graphs/VoxVolShader"',
        text
    )

    # ---------------------------------------------------------
    # 2. Fix include path
    # ---------------------------------------------------------
    text = text.replace(
        '#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"',
        '#include "PBRForwardPass.hlsl"'
    )

    # ---------------------------------------------------------
    # Save result
    # ---------------------------------------------------------
    with open(SHADER_PATH, "w", encoding="utf-8") as f:
        f.write(text)

    print("Shader successfully updated.")


if __name__ == "__main__":
    main()