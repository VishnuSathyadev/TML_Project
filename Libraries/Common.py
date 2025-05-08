from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
import time
import shutil
import glob
import os

def get_previous_month(date_str):
    try:
        # Convert "MMM-YYYY" to a datetime object
        date_obj = datetime.strptime(date_str, "%b-%Y")

        # Subtract one month
        previous_month = date_obj.month - 1
        previous_year = date_obj.year

        # Handle January to December transition
        if  previous_month == 0:
            previous_month =  12
            previous_year  -= 1

        # Convert back to "MMM-YYYY" format
        return datetime(previous_year, previous_month, 1).strftime("%b-%Y")
    except Exception as e:
        print(f"An error occurred while converting current month to previous month: {e}")

def delete_pdf_files(folder_path):
    try:
        pdf_files = glob.glob(os.path.join(folder_path, "*.pdf"))  # Get all PDF files
        for file in pdf_files:
            os.remove(file)  # Delete each file
        return True
    except Exception as e:
        return False
   
def create_provided_directory(directory_path):
    try:
        os.makedirs(directory_path, exist_ok=True)
        return True
    except Exception as e:
        return False

def move_pdfs_to_archive(source_folder, destination_folder):
    try:
        # Ensure source folder exists
        if not os.path.exists(source_folder):
            print(f"Error: Source folder '{source_folder}' does not exist.")

        # Ensure destination folder exists
        os.makedirs(destination_folder, exist_ok=True)

        # Move PDF files
        pdf_files = [f for f in os.listdir(source_folder) if f.lower().endswith(".pdf")]

        if not pdf_files:
            print("No PDF files found in the source folder.")
            return True

        for file in pdf_files:
            source_path = os.path.join(source_folder, file)
            destination_path = os.path.join(destination_folder, file)
            shutil.move(source_path, destination_path)

        print("All PDF files have been moved successfully.")
        return True
    except Exception as e:
        print(f"An error occurred while moving pdf files: {e}")
        return False

def move_unknown_pdf(source_folder, destination_folder):
    try:
        pdf_files = glob.glob(os.path.join(source_folder, "*.pdf"))  # Get all PDF files

        if pdf_files:
            file_to_move = pdf_files[0]  # Take the first found PDF file
            new_file_path = os.path.join(destination_folder, os.path.basename(file_to_move))

            shutil.move(file_to_move, new_file_path)  # Move file without renaming
            print(f"Moved: {file_to_move} → {new_file_path}")
            return True
        else:
            print("No PDF file found to move")
            return False
    except Exception as e:
        print(f"Error: {e}")
        return False
    
def check_pdf_file_exists(folder_path):
    try:
        pdf_files = glob.glob(os.path.join(folder_path, "*.pdf"))
        
        if pdf_files:
            print(f"PDF file(s) found: {pdf_files}")
            return True
        else:
            print("No PDF file found in the specified location")
            return False
    except Exception as e:
        return False

def delete_directory(path):
    try:
        if os.path.exists(path) and os.path.isdir(path):
            shutil.rmtree(path)
            print(f"Deleted directory: {path}")
            return True
        else:
            print(f"Directory not found or not a directory: {path}")
            return False
    except Exception as e:
        print(f"Error deleting directory: {e}")
        return False
    
def run_batch_file(batch_path):
    try:
        os.system(batch_path)
        print(f"Executed: {batch_path}")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False
    
def move_all_files(source_dir, target_dir):
    try:
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)

        for filename in os.listdir(source_dir):
            source_path = os.path.join(source_dir, filename)
            target_path = os.path.join(target_dir, filename)

            if os.path.isfile(source_path):
                shutil.move(source_path, target_path)
                print(f"Moved: {filename}")
        
        print("All files moved successfully.")
        return True

    except Exception as e:
        print(f"Error occurred: {e}")
        return False