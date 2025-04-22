import os
from PyPDF2 import PdfMerger

def merge_pdfs(output_path, acknowledgement_path, main_report_path):
    """
    Merge the acknowledgement PDF and main report PDF into a single document.
    Places the acknowledgement page after the cover page and before TOC.
    """
    merger = PdfMerger()
    
    # Get information about the PDFs
    # We'll insert the acknowledgement after the first page (cover page)
    
    # Add first page from main report (cover page)
    merger.append(main_report_path, pages=(0, 1))
    
    # Add acknowledgement page
    merger.append(acknowledgement_path)
    
    # Add rest of the main report
    merger.append(main_report_path, pages=(1, None))
    
    # Write the merged PDF to file
    merger.write(output_path)
    merger.close()
    
    print(f"PDFs successfully merged to: {output_path}")

if __name__ == "__main__":
    # Define paths
    dir_path = os.path.dirname(os.path.abspath(__file__))
    acknowledgement_path = os.path.join(dir_path, "acknowledgement.pdf")
    main_report_path = os.path.join(dir_path, "projectReport.pdf")
    merged_output_path = os.path.join(dir_path, "finalReport.pdf")
    
    # Check if necessary files exist
    if not os.path.exists(acknowledgement_path):
        print(f"Error: Acknowledgement file not found at {acknowledgement_path}")
        print("Please run acknowledgement.py first.")
        exit(1)
        
    if not os.path.exists(main_report_path):
        print(f"Error: Main report file not found at {main_report_path}")
        print("Please run report.py first.")
        exit(1)
    
    # Merge the PDFs
    merge_pdfs(merged_output_path, acknowledgement_path, main_report_path) 