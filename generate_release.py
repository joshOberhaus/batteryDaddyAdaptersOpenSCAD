#!/usr/bin/env python3
"""
Automated release generator for BatteryDaddy adapters.
Generates STLs for compatible battery/host combinations only.
"""

import subprocess
import sys
from pathlib import Path
from datetime import datetime

# Define compatibility matrix
# Format: battery_type -> list of compatible host batteries
BUTTON_CELL_COMPAT = {
    "CR2450": ["D"],                 # 24.5mm - only fits D
    "CR2032": ["D", "C"],            # 20mm - fits D and C
    "CR2016": ["D", "C"],            # 20mm - fits D and C
    "CR1632": ["D", "C"],            # 16mm - fits D and C
    "CR1616": ["D", "C"],            # 16mm - fits D and C
}

CYLINDER_COMPAT = {
    "A27":   ["D", "C"],      
    "AAAA":  ["D", "C"],
}

def run_openscad(scad_file, output_file, params):
    """Run OpenSCAD to generate an STL file."""
    cmd = ["openscad", "-o", str(output_file)]
    for key, value in params.items():
        cmd.extend(["-D", f"{key}={value}"])
    cmd.append(str(scad_file))
    
    print("Running:", " ".join(cmd))
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True, None
    except subprocess.CalledProcessError as e:
        return False, e.stderr

def generate_button_cell_stls(output_dir):
    """Generate all compatible button cell adapter STLs."""
    print("🔋 Generating button cell adapters...")
    scad_file = Path("button_cell_adapter.scad")
    success_count = 0
    fail_count = 0
    
    for battery, hosts in BUTTON_CELL_COMPAT.items():
        for host in hosts:
            output_file = output_dir / f"{battery}-{host}.stl"
            params = {
                "battery_label": f'"{battery}"',
                "host_battery_type": f'"{host}"'
            }
            
            print(f"  {battery:8} → {host:2}", end=" ... ")
            success, error = run_openscad(scad_file, output_file, params)
            
            if success:
                print("✓")
                success_count += 1
            else:
                print("✗")
                if error:
                    print(f"    Error: {error}")
                fail_count += 1
    
    return success_count, fail_count

def generate_cylinder_stls(output_dir):
    """Generate all compatible cylindrical battery adapter STLs."""
    print("⚡ Generating cylindrical battery adapters...")
    scad_file = Path("cylinder_battery_adapter.scad")
    success_count = 0
    fail_count = 0
    
    for battery, hosts in CYLINDER_COMPAT.items():
        for host in hosts:
            output_file = output_dir / f"{battery}-{host}.stl"
            params = {
                "battery_type": f'"{battery}"',
                "host_battery_type": f'"{host}"'
            }
            
            print(f"  {battery:8} → {host:2}", end=" ... ")
            success, error = run_openscad(scad_file, output_file, params)
            
            if success:
                print("✓")
                success_count += 1
            else:
                print("✗")
                if error:
                    print(f"    Error: {error}")
                fail_count += 1
    
    return success_count, fail_count

def create_manifest(output_dir):
    """Create a manifest of generated files."""
    manifest = f"""# BatteryDaddy Release Manifest
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Button Cell Adapters (Coin Cells)

### CR2450 (24.5mm) - Largest coin cell
- CR2450-D.stl (D holder only)

### CR2032 / CR2016 (20mm) - Standard coin cells
- CR2032-D.stl, CR2032-C.stl
- CR2016-D.stl, CR2016-C.stl

### CR1632 / CR1616 (16mm) - Smaller coin cells
- CR1632-D.stl, CR1632-C.stl, CR1632-AA.stl
- CR1616-D.stl, CR1616-C.stl, CR1616-AA.stl

## Cylindrical Battery Adapters

### A27 (7.75mm diameter, 28mm length)
- A27-D.stl, A27-C.stl

### AAAA (8.3mm diameter, 42.5mm length)
- AAAA-D.stl, AAAA-C.stl

---
Total combinations: {len(BUTTON_CELL_COMPAT) + len(CYLINDER_COMPAT)} battery types
Total files: {sum(len(hosts) for hosts in BUTTON_CELL_COMPAT.values()) + sum(len(hosts) for hosts in CYLINDER_COMPAT.values())} STLs
"""
    
    manifest_file = output_dir / "MANIFEST.txt"
    manifest_file.write_text(manifest)
    print(f"\n📝 Manifest: {manifest_file}")

def main():
    release_name = datetime.now().strftime("Release-%Y-%m-%d_%H%M%S")
    release_dir = Path("releases") / release_name
    stl_dir = release_dir / "stls"
    
    print(f"📦 Creating release: {release_name}\n")
    
    # Create directories
    stl_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate STLs
    button_success, button_fail = generate_button_cell_stls(stl_dir)
    print()
    cylinder_success, cylinder_fail = generate_cylinder_stls(stl_dir)
    
    # Copy source files
    print("\n📄 Copying source files...")
    for scad_file in Path(".").glob("*.scad"):
        import shutil
        shutil.copy(scad_file, release_dir / scad_file.name)
        print(f"  {scad_file.name}")
    
    import shutil
    if Path("README.md").exists():
        shutil.copy("README.md", release_dir / "README.md")
        print("  README.md")
    
    # Create manifest
    create_manifest(release_dir)
    
    # Summary
    total_success = button_success + cylinder_success
    total_fail = button_fail + cylinder_fail
    
    print(f"\n{'='*50}")
    print(f"✓ Successfully generated: {total_success} STLs")
    if total_fail > 0:
        print(f"✗ Failed: {total_fail} STLs")
    print(f"📁 Release location: {release_dir.absolute()}")
    print(f"{'='*50}")
    
    return 0 if total_fail == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
