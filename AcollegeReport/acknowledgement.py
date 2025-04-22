import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY

def create_acknowledgement(output_path):
    """Create a PDF with an acknowledgement page."""
    # Set up the document
    doc = SimpleDocTemplate(
        output_path,
        pagesize=A4,
        rightMargin=72,
        leftMargin=72,
        topMargin=72,
        bottomMargin=72
    )
    
    # Get the styles
    styles = getSampleStyleSheet()
    
    # Create custom styles
    styles.add(ParagraphStyle(
        name='AckTitle',
        parent=styles['Heading1'],
        fontSize=22,
        alignment=TA_CENTER,
        spaceAfter=30
    ))
    
    styles.add(ParagraphStyle(
        name='AckBody',
        parent=styles['Normal'],
        fontSize=12,
        leading=16,
        alignment=TA_JUSTIFY,
        firstLineIndent=20,
        spaceAfter=12
    ))
    
    styles.add(ParagraphStyle(
        name='AckSignature',
        parent=styles['Normal'],
        fontSize=12,
        alignment=TA_CENTER,
        spaceBefore=30
    ))
    
    # List of content to add to the PDF
    content = []
    
    # Add acknowledgement title
    content.append(Spacer(1, 1*inch))
    content.append(Paragraph("ACKNOWLEDGEMENT", styles['AckTitle']))
    content.append(Spacer(1, 0.5*inch))
    
    # Add acknowledgement text - using exact text from user
    acknowledgement_text = """
    Development of this project required the efforts of many people.
    We have completed the project on "xShop (Shop Management System using flutter)"
    
    I would like to express my gratitude and thanks to my guide Prof. J. R. Kolekar who gave me the opportunity to do this project on the topic xShop website using Minimax Algorithm.
    
    Introduced to this topic, that helped me in doing a lot of Research, and I came to know about so many new things.
    
    In this project, I have received timely help, guidance from my friends and received the help from other teachers who helped me a lot in completing this project within the specified time period.
    """
    
    # Clean up the text and add it to the content
    acknowledgement_text = ' '.join(line.strip() for line in acknowledgement_text.split('\n') if line.strip())
    content.append(Paragraph(acknowledgement_text, styles['AckBody']))
    
    # Add spacer before signature
    content.append(Spacer(1, 1.5*inch))
    
    # Add signature
    content.append(Paragraph("Rathod Abhiraj Bharat", styles['AckSignature']))
    
    # Build the PDF
    doc.build(content)
    print(f"Acknowledgement page generated at: {output_path}")

if __name__ == "__main__":
    # Create PDF at the specified path
    output_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(output_dir, "acknowledgement.pdf")
    create_acknowledgement(output_path) 