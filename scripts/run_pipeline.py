from pathlib import Path
import subprocess
import sys
import time


PROJECT_ROOT = Path(__file__).resolve().parent.parent

STEPS = [
    ("Bronze load", PROJECT_ROOT / "scripts/bronze/02_load_bronze_data.sql"),
    ("Silver load", PROJECT_ROOT / "scripts/silver/02_load_silver_data.sql"),
    ("Gold load", PROJECT_ROOT / "scripts/gold/02_load_gold_data.sql"),
    ("Silver DQ", PROJECT_ROOT / "tests/data_quality/01_test_silver.sql"),
    ("Gold DQ", PROJECT_ROOT / "tests/data_quality/02_test_gold.sql"),
]


def run_sql_script(name, script_path):
    print(f"\n[{name}]")
    print(f"Running: {script_path}")

    timer = time.perf_counter()

    result = subprocess.run(
        [
            "psql",
            "-w",
            "-U", "postgres",
            "-d", "datawarehouse",
            "-f", str(script_path),
        ],
        text=True,
        capture_output=True,
    )

    duration = time.perf_counter() - timer

    if result.stdout:
        print(result.stdout, end="")

    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)

    if result.returncode != 0:
        print(f"\n✗ {name} FAILED ({duration:.2f}s)")
        return False, duration

    print(f"✓ {name} completed ({duration:.2f}s)")
    return True, duration


def main():
    print("=" * 60)
    print("DATA WAREHOUSE PIPELINE")
    print("=" * 60)

    results = []
    pipeline_start = time.perf_counter()

    for name, script_path in STEPS:
        if not script_path.exists():
            print(f"\n✗ Script not found: {script_path}")
            sys.exit(1)

        success, duration = run_sql_script(name, script_path)
        results.append((name, success, duration))

        if not success:
            break

    total_duration = time.perf_counter() - pipeline_start

    print("\n" + "=" * 60)
    print("PIPELINE SUMMARY")
    print("=" * 60)

    for name, success, duration in results:
        status = "PASS" if success else "FAIL"
        print(f"{name:<20} {status:<8} {duration:>8.2f}s")

    print("-" * 60)
    print(f"{'Total duration':<28}{total_duration:>8.2f}s")

    if any(not success for _, success, _ in results):
        print("\nPIPELINE FAILED")
        sys.exit(1)

    print("\nPIPELINE COMPLETED SUCCESSFULLY")


if __name__ == "__main__":
    main()