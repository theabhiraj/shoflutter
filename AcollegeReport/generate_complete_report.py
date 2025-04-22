import os
import subprocess
import sys

def run_script(script_path):
    """Run a Python script and return True if successful."""
    try:
        result = subprocess.run([sys.executable, script_path], check=True)
        return result.returncode == 0
    except subprocess.CalledProcessError:
        return False
    except Exception as e:
        print(f"Error running {script_path}: {e}")
        return False

def main():
    """Generate the complete project report with acknowledgement page."""
    # Get the directory of this script
    dir_path = os.path.dirname(os.path.abspath(__file__))
    
    # Define paths to scripts
    report_script = os.path.join(dir_path, "report.py")
    acknowledgement_script = os.path.join(dir_path, "acknowledgement.py")
    merge_script = os.path.join(dir_path, "merge_pdfs.py")
    
    # Check if all required scripts exist
    for script in [report_script, acknowledgement_script, merge_script]:
        if not os.path.exists(script):
            print(f"Error: Required script not found: {script}")
            return False
    
    # Step 1: Generate the main report
    print("Generating main project report...")
    if not run_script(report_script):
        print("Error: Failed to generate main project report.")
        return False
    
    # Step 2: Generate the acknowledgement page
    print("Generating acknowledgement page...")
    if not run_script(acknowledgement_script):
        print("Error: Failed to generate acknowledgement page.")
        return False
    
    # Step 3: Merge the PDFs
    print("Merging documents...")
    if not run_script(merge_script):
        print("Error: Failed to merge PDFs.")
        return False
    
    # Final output
    output_path = os.path.join(dir_path, "finalReport.pdf")
    print(f"\nComplete project report with acknowledgement has been generated:")
    print(f"-> {output_path}")
    print("\nProcess completed successfully!")
    return True

if __name__ == "__main__":
    success = main()
    if not success:
        print("\nReport generation process failed. Please check the errors above.")
        sys.exit(1)
    sys.exit(0) 