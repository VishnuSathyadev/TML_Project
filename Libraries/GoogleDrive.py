from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.http import MediaFileUpload
from googleapiclient.http import MediaIoBaseDownload
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google.oauth2 import service_account
import os
import io

# If modifying these SCOPES, delete the file token.json.
# SCOPES = ['https://www.googleapis.com/auth/drive.metadata.readonly']



#Authenticate Google Drive using a service account
def authenticate_service_account():
    try:
        # If modifying these SCOPES, delete the file token.json.
        SCOPES = ['https://www.googleapis.com/auth/drive']
        creds = service_account.Credentials.from_service_account_file(
            'service_token.json',
            scopes=SCOPES
        )
        service = build('drive', 'v3', credentials=creds)
        print("Authenticated successfully")
        return service
    except Exception as e:
        print(f"Failed to authenticate: {e}")
        return None


# Function to check if a file exists in a specific folder in Google Drive
def check_file_exists(folder_id, file_name):
    try:
        service = authenticate_service_account()
        # Query to find files with the specific name in the specific folder
        query = f"name = '{file_name}' and '{folder_id}' in parents and trashed = false"
        
        # Execute the query
        results = service.files().list(
            q=query,
            pageSize=1,
            fields="files(id, name)"
        ).execute()
        
        files = results.get('files', [])
        
        if files:
            print(f"File '{file_name}' exists in the specified folder.")
            print(f"File ID: {files[0]['id']}")
            return True
        else:
            print(f"File '{file_name}' does not exist in the specified folder.")
            return False      
    except HttpError as error:
        print(f"An error occurred: {error}")
        return False


#Function to create a folder in Google Drive    
def create_folder(folder_name, parent_id=None):
    try:
        service = authenticate_service_account()

        # Check if folder already exists under parent
        query = f"mimeType='application/vnd.google-apps.folder' and name='{folder_name}' and trashed=false"
        if parent_id:
            query += f" and '{parent_id}' in parents"

        response = service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
        files = response.get('files', [])

        if files:
            print(f"Folder '{folder_name}' already exists. Using ID: {files[0]['id']}")
            return files[0]['id']
        
        # Create new folder if not found
        folder_metadata = {
            'name': folder_name,
            'mimeType': 'application/vnd.google-apps.folder'
        }
        if parent_id:
            folder_metadata['parents'] = [parent_id]

        folder = service.files().create(
            body=folder_metadata,
            fields='id'
        ).execute()
        print(f"Created folder: '{folder_name}' (ID: {folder.get('id')})")
        return folder.get('id')

    except HttpError as error:
        print(f"Failed to create or find folder '{folder_name}': {error}")
        return None


#Function to create a nested folder path inside Google Drive
def create_nested_folders(folder_path_list, root_folder_id):
    try:
        service = authenticate_service_account()
        current_parent_id = root_folder_id
        for folder_name in folder_path_list:
            current_parent_id = create_folder(folder_name, current_parent_id)
            if not current_parent_id:
                raise Exception(f"Failed to create folder '{folder_name}'")
        return current_parent_id
    except Exception as e:
        print(f"Error in creating nested folders: {e}")
        return None


#Function to upload a file to a folder path inside Google Drive
def upload_file_to_folder(folder_id, file_path):
    try:
        service = authenticate_service_account()
        file_name = os.path.basename(file_path)

        # Step 1: Check if file already exists in the folder
        query = f"name = '{file_name}' and '{folder_id}' in parents and trashed = false"
        response = service.files().list(q=query, spaces='drive', fields='files(id)').execute()
        existing_files = response.get('files', [])

        file_metadata = {
            'name': file_name,
            'parents': [folder_id]
        }

        media = MediaFileUpload(file_path, resumable=True)

        if existing_files:
            # File exists – update it
            file_id = existing_files[0]['id']
            updated_file = service.files().update(
                fileId=file_id,
                media_body=media,
                fields='id'
            ).execute()
            print(f"Replaced existing file: {file_name} (ID: {updated_file.get('id')})")
        else:
            # File doesn't exist – create it
            uploaded_file = service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id'
            ).execute()
            print(f"Uploaded new file: {file_name} (ID: {uploaded_file.get('id')})")
        return True
    except HttpError as error:
        print(f"Error uploading file '{file_path}': {error}")
        return False


#Function to download a file from Google Drive
def download_file(folder_id, file_name, destination_path):
    try:
        service = authenticate_service_account()

        # Step 1: Search for the file in the folder
        query = f"name = '{file_name}' and '{folder_id}' in parents and trashed = false"
        results = service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
        files = results.get('files', [])

        if not files:
            print(f"File '{file_name}' not found in folder.")
            return False

        file_id = files[0]['id']
        print(f"Downloading '{file_name}' (ID: {file_id})...")

        # Step 2: Prepare download
        request = service.files().get_media(fileId=file_id)
        fh = io.FileIO(destination_path, 'wb')
        downloader = MediaIoBaseDownload(fh, request)

        done = False
        while not done:
            status, done = downloader.next_chunk()
            print(f"Download progress: {int(status.progress() * 100)}%")

        print(f"File downloaded to: {destination_path}")
        return True

    except HttpError as error:
        print(f"Error downloading file: {error}")
        return False

# Specify the folder ID and file name to check
# folder_id = '10yfWmcEAhYNHVyALpKrVrPqTAT0fjP3I'  # Replace with your folder ID
# file_name = 'StatusTrackerExcel.xlsx'     # Replace with your file name
# file_path = r"C:\Users\Vishnu Sathyadev\Desktop\TML Project\StatusTrackerExcel_Test.xlsx"
# destination_path= r"C:\Users\Vishnu Sathyadev\Desktop\TML Project\TestFolder\test.xlsx"

# # Check if file exists
# status = check_file_exists(folder_id, file_name)
# folder_path = ["2025_Reports", "Final_Submissions", "April"]

# final_folder_id = create_nested_folders(folder_path, folder_id)

# if final_folder_id:
#     download_file(final_folder_id, 'StatusTrackerExcel_Test.xlsx', destination_path)
#     upload_file_to_folder(final_folder_id, file_path)
