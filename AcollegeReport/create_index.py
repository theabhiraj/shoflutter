import os
from PyPDF2 import PdfReader
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.enums import TA_CENTER, TA_LEFT
import re

def extract_headings(pdf_path):
    """Extract headings from a PDF file."""
    reader = PdfReader(pdf_path)
    headings = []
    
    # Skip first page for projectReport.pdf
    start_page = 1 if "projectReport" in pdf_path else 0
    
    # Only examine pages 1-20 for headings, as specified by the user
    end_page = min(20, len(reader.pages)) if "projectReport" in pdf_path else len(reader.pages)
    
    for i in range(start_page, end_page):
        page = reader.pages[i]
        text = page.extract_text()
        
        # Try to find the main heading on each page
        lines = text.split('\n')
        if lines:
            # Use the first non-empty line that looks like a heading
            for line in lines:
                line = line.strip()
                if line and len(line) < 100 and not line.startswith('Page') and not re.match(r'^\d+$', line):
                    headings.append((line, i+1))  # i+1 because page numbers start at 1
                    break
    
    return headings

def create_index_pdf(output_path, report_pdf_path, acknowledgement_pdf_path):
    """Create an index PDF with entries from both PDFs."""
    # Get headings from both PDFs
    report_headings = extract_headings(report_pdf_path)
    ack_headings = extract_headings(acknowledgement_pdf_path)
    
    # Set up the document
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        rightMargin=60,
        leftMargin=60,
        topMargin=50,
        bottomMargin=50
    )
    
    # Get the styles
    styles = getSampleStyleSheet()
    
    # Create custom styles with improved formatting
    styles.add(ParagraphStyle(
        name='IndexTitle',
        parent=styles['Heading1'],
        fontSize=18,
        alignment=TA_CENTER,
        spaceAfter=15,
        fontName='Helvetica-Bold'
    ))
    
    styles.add(ParagraphStyle(
        name='IndexEntry',
        parent=styles['Normal'],
        fontSize=10,
        leading=12,
        alignment=TA_LEFT,
        spaceAfter=2,
        leftIndent=20,
        fontName='Helvetica'
    ))
    
    styles.add(ParagraphStyle(
        name='IndexSection',
        parent=styles['Heading2'],
        fontSize=12,
        leading=14,
        alignment=TA_LEFT,
        spaceBefore=6,
        spaceAfter=3,
        fontName='Helvetica-Bold'
    ))
    
    # List of content to add to the PDF
    content = []
    
    # Add index title
    content.append(Spacer(1, 0.2*inch))
    content.append(Paragraph("INDEX", styles['IndexTitle']))
    content.append(Spacer(1, 0.1*inch))
    
    # 1. Add acknowledgement entry if available
    if ack_headings:
        content.append(Paragraph("ACKNOWLEDGEMENT", styles['IndexSection']))
        content.append(Paragraph(f"Acknowledgement ................................. Page 1", styles['IndexEntry']))
    
    # 2. Add report entries (pages 1-20)
    content.append(Paragraph("PROJECT REPORT", styles['IndexSection']))
    for heading, page_num in report_headings:
        # Truncate very long headings
        if len(heading) > 40:
            heading = heading[:37] + "..."
        # Create a line with dots connecting the heading to the page number
        dots = "." * (40 - len(heading))
        content.append(Paragraph(f"{heading} {dots} Page {page_num}", styles['IndexEntry']))
    
    # 3. Add images section (pages 21-35)
    content.append(Paragraph("IMAGES", styles['IndexSection']))
    # Show images as a range instead of individual entries
    content.append(Paragraph(f"Project Screenshots ............................ Pages 21-35", styles['IndexEntry']))
    
    # 4. Add code section (starting from page 36)
    content.append(Paragraph("CODE", styles['IndexSection']))
    content.append(Paragraph(f"Implementation Code ............................ Page 36", styles['IndexEntry']))
    
    # Build the PDF
    doc.build(content)
    print(f"Index page generated at: {output_path}")

if __name__ == "__main__":
    # Define paths
    dir_path = os.path.dirname(os.path.abspath(__file__))
    report_pdf_path = os.path.join(dir_path, "projectReport.pdf")
    acknowledgement_pdf_path = os.path.join(dir_path, "acknowledgement.pdf")
    index_pdf_path = os.path.join(dir_path, "index.pdf")
    
    # Check if necessary files exist
    if not os.path.exists(report_pdf_path):
        print(f"Error: Report file not found at {report_pdf_path}")
        print("Please run report.py first.")
        exit(1)
        
    if not os.path.exists(acknowledgement_pdf_path):
        print(f"Error: Acknowledgement file not found at {acknowledgement_pdf_path}")
        print("Please run acknowledgement.py first.")
        exit(1)
    
    # Create the index PDF
    create_index_pdf(index_pdf_path, report_pdf_path, acknowledgement_pdf_path)