import os
from PyPDF2 import PdfMerger, PdfReader

def combine_pdfs(output_path, report_pdf_path, acknowledgement_pdf_path, index_pdf_path):
    """
    Combine PDFs in the following order:
    1. Cover page from projectReport.pdf
    2. Index page
    3. Acknowledgement page
    4. Rest of projectReport.pdf (skipping cover page)
    """
    merger = PdfMerger()
    
    # Add first page from project report (cover page)
    report_reader = PdfReader(report_pdf_path)
    merger.append(report_reader, pages=(0, 1))
    
    # Add index page
    merger.append(index_pdf_path)
    
    # Add acknowledgement page
    merger.append(acknowledgement_pdf_path)
    
    # Add rest of the report (skip first page)
    merger.append(report_reader, pages=(1, len(report_reader.pages)))
    
    # Write the merged PDF to file
    merger.write(output_path)
    merger.close()
    
    print(f"Final report generated successfully at: {output_path}")

def main():
    # Define paths
    dir_path = os.path.dirname(os.path.abspath(__file__))
    report_pdf_path = os.path.join(dir_path, "projectReport.pdf")
    acknowledgement_pdf_path = os.path.join(dir_path, "acknowledgement.pdf")
    index_pdf_path = os.path.join(dir_path, "index.pdf")
    final_report_path = os.path.join(dir_path, "finalReport.pdf")
    
    # Check if necessary files exist
    missing_files = []
    
    if not os.path.exists(report_pdf_path):
        missing_files.append(f"Report (projectReport.pdf)")
    
    if not os.path.exists(acknowledgement_pdf_path):
        missing_files.append(f"Acknowledgement (acknowledgement.pdf)")
    
    if not os.path.exists(index_pdf_path):
        missing_files.append(f"Index (index.pdf)")
    
    if missing_files:
        print("Error: The following required files are missing:")
        for file in missing_files:
            print(f"- {file}")
        print("\nPlease generate these files first by running:")
        if "Report" in str(missing_files):
            print("- report.py")
        if "Acknowledgement" in str(missing_files):
            print("- acknowledgement.py")
        if "Index" in str(missing_files):
            print("- create_index.py")
        return False
    
    # Combine PDFs
    combine_pdfs(final_report_path, report_pdf_path, acknowledgement_pdf_path, index_pdf_path)
    return True

if __name__ == "__main__":
    main() 