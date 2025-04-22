import os
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, PageBreak, Spacer
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib import colors
import markdown2
import re

def convert_markdown_to_html(markdown_text):
    """Convert markdown text to HTML for ReportLab."""
    # Use markdown2 to convert the text
    html = markdown2.markdown(markdown_text)
    
    # Clean up some markdown elements not perfectly handled by reportlab
    html = html.replace('<code>', '<font face="Courier">')
    html = html.replace('</code>', '</font>')
    
    # Replace markdown code blocks with styled text
    code_block_pattern = r'<pre><code>(.*?)</code></pre>'
    def code_block_replace(match):
        code_content = match.group(1)
        code_content = code_content.replace('\n', '<br/>')
        return f'<font face="Courier" color="darkblue">{code_content}</font>'
    
    html = re.sub(code_block_pattern, code_block_replace, html, flags=re.DOTALL)
    
    return html

class DocTemplate(SimpleDocTemplate):
    def __init__(self, filename, **kw):
        SimpleDocTemplate.__init__(self, filename, **kw)
        self.title_list = []
        
    def afterFlowable(self, flowable):
        """Register TOC entries."""
        if isinstance(flowable, Paragraph):
            text = flowable.getPlainText()
            style = flowable.style.name
            if style == 'CustomTitle':
                self.title_list.append((0, text, self.page))
                key = 'h1-%s' % text
                self.canv.bookmarkPage(key)
                self.canv.addOutlineEntry(text, key, 0, 0)
            elif style == 'CustomHeading1':
                self.title_list.append((1, text, self.page))
                key = 'h2-%s' % text
                self.canv.bookmarkPage(key)
                self.canv.addOutlineEntry(text, key, 1, 0)
            elif style == 'CustomHeading2':
                self.title_list.append((2, text, self.page))
                key = 'h3-%s' % text
                self.canv.bookmarkPage(key)
                self.canv.addOutlineEntry(text, key, 2, 0)

def create_pdf(output_path):
    """Create PDF from text files in the contents directory."""
    # Set up the document
    doc = DocTemplate(
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
        name='CustomTitle',
        parent=styles['Heading1'],
        fontSize=20,
        alignment=TA_CENTER,
        spaceAfter=30
    ))
    
    styles.add(ParagraphStyle(
        name='CustomHeading1',
        parent=styles['Heading1'],
        fontSize=16,
        spaceAfter=12
    ))
    
    styles.add(ParagraphStyle(
        name='CustomHeading2',
        parent=styles['Heading2'],
        fontSize=14,
        spaceAfter=10
    ))
    
    styles.add(ParagraphStyle(
        name='CustomNormal',
        parent=styles['Normal'],
        fontSize=11,
        leading=14,
        alignment=TA_JUSTIFY
    ))
    
    styles.add(ParagraphStyle(
        name='TOCHeading',
        parent=styles['Heading1'],
        fontSize=18,
        alignment=TA_CENTER,
        spaceAfter=20
    ))
    
    # List of content to add to the PDF
    content = []
    
    # Add cover page
    cover_title = "xShop Management System"
    cover_subtitle = "Project Documentation Report"
    current_date = datetime.now().strftime("%B %d, %Y")
    
    content.append(Spacer(1, 2*inch))
    content.append(Paragraph(f'<font size="30">{cover_title}</font>', styles['CustomTitle']))
    content.append(Spacer(1, 0.25*inch))
    content.append(Paragraph(f'<font size="18">{cover_subtitle}</font>', styles['CustomTitle']))
    content.append(Spacer(1, 2*inch))
    content.append(Paragraph('<font size="14">Prepared by: [Your Name]</font>', styles['CustomNormal']))
    content.append(Paragraph('<font size="14">Course: [Your Course]</font>', styles['CustomNormal']))
    content.append(Paragraph(f'<font size="14">Date: {current_date}</font>', styles['CustomNormal']))
    content.append(PageBreak())
    
    # Add table of contents
    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle(name='TOC1', fontSize=14, leading=16),
        ParagraphStyle(name='TOC2', fontSize=12, leading=14, leftIndent=20),
        ParagraphStyle(name='TOC3', fontSize=10, leading=12, leftIndent=40),
    ]
    
    content.append(Paragraph("Table of Contents", styles['TOCHeading']))
    content.append(Spacer(1, 0.2*inch))
    content.append(toc)
    content.append(PageBreak())
    
    # Get list of content files
    contents_dir = os.path.join(os.path.dirname(__file__), 'contents')
    content_files = sorted([f for f in os.listdir(contents_dir) if f.endswith('.txt')])
    
    # Process each content file
    for file in content_files:
        file_path = os.path.join(contents_dir, file)
        
        with open(file_path, 'r', encoding='utf-8') as f:
            markdown_content = f.read()
        
        # Convert markdown to HTML
        html_content = convert_markdown_to_html(markdown_content)
        
        # Split the content by headers
        sections = re.split(r'(<h[1-6].*?</h[1-6]>)', html_content)
        
        # Start a new page for each file
        content.append(PageBreak())
        
        for section in sections:
            if section:
                if re.match(r'<h1', section):
                    # This is a main heading (from # in markdown)
                    section = section.replace('<h1>', '').replace('</h1>', '')
                    content.append(Paragraph(section, styles['CustomTitle']))
                elif re.match(r'<h2', section):
                    # This is a secondary heading (from ## in markdown)
                    section = section.replace('<h2>', '').replace('</h2>', '')
                    content.append(Paragraph(section, styles['CustomHeading1']))
                elif re.match(r'<h3', section):
                    # This is a tertiary heading (from ### in markdown)
                    section = section.replace('<h3>', '').replace('</h3>', '')
                    content.append(Paragraph(section, styles['CustomHeading2']))
                else:
                    # Regular content
                    if section.strip():
                        content.append(Paragraph(section, styles['CustomNormal']))
                        content.append(Spacer(1, 0.1*inch))
    
    # Build the PDF with table of contents
    doc.multiBuild(content)
    print(f"PDF generated at: {output_path}")

if __name__ == "__main__":
    # Check if the contents directory exists, if not create it
    contents_dir = os.path.join(os.path.dirname(__file__), 'contents')
    if not os.path.exists(contents_dir):
        os.makedirs(contents_dir)
        print(f"Created directory: {contents_dir}")
    
    # Create PDF at the specified path
    output_path = r"D:\abhiraj\xProjects\Flutter\shoflutter\AcollegeReport\projectReport.pdf"
    create_pdf(output_path)
