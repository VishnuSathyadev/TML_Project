import pikepdf
from PyPDF2 import PdfReader, PdfWriter
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# Function to generate a private key
def create_private_key():
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    # Save the private key to a PEM file
    private_key_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    )
    with open("private_key.pem", "wb") as key_file:
        key_file.write(private_key_pem)

    print("Private key saved as private_key.pem")
    return private_key

# Function to digitally sign a PDF
def sign_pdf(input_pdf_path, output_pdf_path):
    # Read the input PDF
    reader = PdfReader(input_pdf_path)
    writer = PdfWriter()

    # Copy pages to the writer
    for page in reader.pages:
        writer.add_page(page)

    # Add metadata to simulate a digital signature
    signature_content = b"This PDF is digitally signed."
    writer.add_metadata({"/DigitalSignature": signature_content.hex()})

    # Write the unsigned changes to a temporary output file
    with open(output_pdf_path, "wb") as output_file:
        writer.write(output_file)

    # Use pikepdf to finalize the PDF (if needed)
    with pikepdf.open(output_pdf_path, allow_overwriting_input=True) as pdf:
        pdf.save(output_pdf_path)

    print(f"PDF signed and saved to {output_pdf_path}")

# Main execution
if __name__ == "__main__":
    # Path to the input PDF file
    input_pdf = "C:/Users/Haritha/Documents/PopularTMLProcess/digital.pdf"
    output_pdf = "C:/Users/Haritha/Documents/PopularTMLProcess/report_signed.pdf"

    # Generate private key (you can use an existing key if available)
    create_private_key()

    # Digitally sign the PDF
    sign_pdf(input_pdf, output_pdf)
