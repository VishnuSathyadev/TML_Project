from openpyxl import load_workbook, Workbook
from openpyxl.styles import Font, Alignment
from openpyxl.styles import numbers
from datetime import datetime
import pandas as pd
import openpyxl
import os


#Function to read a excel sheet
def read_excel_file(file_path, sheet):
    try:
        df = pd.read_excel(file_path, sheet_name = sheet, dtype=str, engine='openpyxl')
        df = df.dropna(how='all')
        df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
        return df
    except Exception as e:
        print(f"An error occurred while reading the excel file: {e}")

def unique_column_values_as_list(df, column_header):
    try:
        # Fetch all unique values in the column as a list
        unique_customer_ids = df[df[column_header].notna() & (df[column_header] != '')][column_header].unique().tolist()
        return unique_customer_ids
    except Exception as e:
        print(f"An error occurred while filtering unique values: {e}")

def filter_data_table_for_specific_column_value(df, column_name, column_value):
    try:
        filtered_df = df[df[column_name] == column_value]
        return filtered_df.to_dict(orient='records')
    except Exception as e:
        print(f"An error occurred while filtering data frame: {e}")  

def append_data_to_excel(file_path, sheet_name, data_dict):
    try:
        if os.path.exists(file_path):
            wb = load_workbook(file_path)
        else:
            wb = Workbook()
            default_sheet = wb.active
            wb.remove(default_sheet)

        if sheet_name in wb.sheetnames:
            ws = wb[sheet_name]
        else:
            ws = wb.create_sheet(sheet_name)

        # Remove empty first row if it exists
        if ws.max_row == 1 and ws.max_column == 1 and ws.cell(row=1, column=1).value is None:
            ws.delete_rows(1)

        # If sheet is now empty, write headers
        if ws.max_row == 1:
            ws.append(list(data_dict.keys()))

        # Append the data
        ws.append(list(data_dict.values()))

        wb.save(file_path)

    except Exception as e:
        print(f"An error occurred while appending data to excel: {e}")

def update_excel_cell(file_path, search_column, search_value, updated_data, sheet):
    try:
        # Load the workbook and worksheet
        wb = load_workbook(file_path)
        ws = wb[sheet]

        # Find the column index of the search_column (header name)
        column_index = None
        for col in ws.iter_cols(min_row=1, max_row=1):
            if str(col[0].value).strip() == str(search_column).strip():
                column_index = col[0].column
                break

        if column_index is None:
            print(f"Column with header '{search_column}' not found.")
            return

        # Find the row that matches the search condition based on search_column's header
        row_index = None
        for row in range(2, ws.max_row + 1):  # Start from 2 to skip the header row
            cell_value = ws.cell(row=row, column=column_index).value
            if cell_value is not None and str(cell_value).strip() == str(search_value).strip():
                row_index = row
                break

        if row_index:
            # Update the specific row with updated data
            for col_name, value in updated_data.items():
                # Find the column index for the column name in updated_data
                for col in ws.iter_cols(min_row=1, max_row=1):
                    if str(col[0].value).strip() == str(col_name).strip():
                        column_index_to_update = col[0].column
                        ws.cell(row=row_index, column=column_index_to_update).value = value

            # Save the workbook
            wb.save(file_path)
            print(f"Row with {search_column} = {search_value} has been updated.")
        else:
            print(f"No row found where {search_column} = {search_value}.")

    except Exception as e:
        print(f"An error occurred while updating the excel file: {e}")

def get_column_index(column_name, sheet_name, file_path):
    try:
        # Open the workbook
        workbook = openpyxl.load_workbook(file_path)

        # Get the desired sheet
        sheet = workbook[sheet_name]

        # Read the first row (headers)
        headers = [cell.value for cell in sheet[1]]

        # Find the column index based on the column name
        if column_name in headers:
            column_index = headers.index(column_name) + 1  # Adding 1 for 1-based index
            return column_index
        else:
            return None  # Column name not found
    except Exception as e:
        print(f"Error: {e}")
        return None
    
def check_value_in_column(file_path, sheet_name, column_name, value_to_check):
    try:
        wb = openpyxl.load_workbook(file_path)

        if sheet_name not in wb.sheetnames:
            return False  # Sheet not found

        ws = wb[sheet_name]

        header_row_index = None
        column_index = None

        # Scan all rows to find the header row containing the column name
        for i, row in enumerate(ws.iter_rows(), start=1):
            row_values = [cell.value for cell in row]
            if column_name in row_values:
                header_row_index = i
                column_index = row_values.index(column_name) + 1  # 1-based index
                break

        if header_row_index is None or column_index is None:
            return False  # Column not found

        # Search the specified column from the row after the header
        for row in ws.iter_rows(min_row=header_row_index + 1, min_col=column_index, max_col=column_index):
            if row[0].value == value_to_check:
                return True

        return False  # Value not found

    except Exception as e:
        print(f"Error: {e}")
        return False    

def update_excel_rows(file_path, sheet_name, match_conditions, update_values):
    try:
        # Load workbook and target sheet
        wb = load_workbook(file_path)
        if sheet_name not in wb.sheetnames:
            raise ValueError(f"Sheet '{sheet_name}' not found in the workbook.")
        ws = wb[sheet_name]

        # Get header to index mapping
        headers = {cell.value: idx for idx, cell in enumerate(ws[1], start=1)}
        
        updated_count = 0

        # Loop through data rows
        for row in ws.iter_rows(min_row=2):
            if all(str(row[headers[col]-1].value).strip() == str(val) for col, val in match_conditions.items()):
                for update_col, new_val in update_values.items():
                    if update_col in headers:
                        if isinstance(new_val, float) and new_val.is_integer():
                            new_val = int(new_val)
                        row[headers[update_col]-1].value = new_val
                updated_count += 1

        # Save the workbook
        wb.save(file_path)
        print(f"Update completed. {updated_count} row(s) modified.")
        return True
    except Exception as e:
        print(f"An error occurred: {e}")
        return False
    
def filter_data_table_for_multiple_column_values(df, conditions_dict):
    try:
        for column_name, column_value in conditions_dict.items():
            df = df[df[column_name] == column_value]
        return df.to_dict(orient='records')
    except Exception as e:
        print(f"An error occurred while filtering data frame: {e}")

def check_values_in_multiple_columns(file_path, sheet_name, column_value_dict):
    try:
        wb = openpyxl.load_workbook(file_path)

        if sheet_name not in wb.sheetnames:
            return False  # Sheet not found

        ws = wb[sheet_name]

        header_row_index = None
        header_mapping = {}

        # Find header row and map column names to indexes
        for i, row in enumerate(ws.iter_rows(), start=1):
            row_values = [cell.value for cell in row]
            if all(col in row_values for col in column_value_dict.keys()):
                header_row_index = i
                header_mapping = {col: row_values.index(col) + 1 for col in column_value_dict}
                break

        if header_row_index is None:
            return False  # Required columns not found

        # Loop through data rows
        for row in ws.iter_rows(min_row=header_row_index + 1):
            match = True
            for col_name, expected_value in column_value_dict.items():
                col_idx = header_mapping[col_name] - 1  # 0-based index
                cell_value = row[col_idx].value
                if str(cell_value).strip() != str(expected_value).strip():
                    match = False
                    break
            if match:
                return True  # Found matching row

        return False  # No matching row found

    except Exception as e:
        print(f"Error: {e}")
        return False
    
def delete_excel_sheet(file_path, sheet_to_delete):
    try:
        wb = load_workbook(file_path)
        
        if sheet_to_delete not in wb.sheetnames:
            print(f"Sheet '{sheet_to_delete}' not found in the workbook.")
            return False
        
        # Cannot delete the only sheet in a workbook
        if len(wb.sheetnames) == 1:
            print("Cannot delete the only sheet in the workbook.")
            return False
        
        del wb[sheet_to_delete]
        wb.save(file_path)
        print(f"Sheet '{sheet_to_delete}' deleted successfully.")
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def append_data_to_excel_by_data_type(file_path, sheet_name, data_dict): 
    try:
        if os.path.exists(file_path):
            wb = load_workbook(file_path)
        else:
            wb = Workbook()
            default_sheet = wb.active
            wb.remove(default_sheet)

        if sheet_name in wb.sheetnames:
            ws = wb[sheet_name]
        else:
            ws = wb.create_sheet(sheet_name)

        # Remove empty first row if it exists
        if ws.max_row == 1 and ws.max_column == 1 and ws.cell(row=1, column=1).value is None:
            ws.delete_rows(1)

        # If sheet is now empty, write headers
        if ws.max_row == 1:
            ws.append(list(data_dict.keys()))

        # Append the data with type checking and formatting
        row_values = list(data_dict.values())
        ws.append(row_values)
        new_row_idx = ws.max_row

        for col_idx, value in enumerate(row_values, start=1):
            cell = ws.cell(row=new_row_idx, column=col_idx)

            # Try to convert string to datetime
            if isinstance(value, str):
                cleaned_value = value.strip().replace("–", "-").replace("—", "-")
                try:
                    parsed_date = datetime.strptime(cleaned_value, "%d-%m-%Y")
                    cell.value = parsed_date.strftime("%d/%m/%Y")
                    cell.number_format = 'dd/mm/yyyy'
                    continue
                except ValueError:
                    pass  # Not a date

                # Try number conversion
                try:
                    if '.' in value:
                        num = float(value)
                        cell.value = num
                        cell.number_format = '0.00'
                    else:
                        num = int(value)
                        cell.value = num
                        cell.number_format = '0'
                    continue
                except ValueError:
                    pass  # Leave as text

            elif isinstance(value, (int, float)):
                cell.number_format = numbers.FORMAT_NUMBER_00 if isinstance(value, float) else numbers.FORMAT_NUMBER

            elif isinstance(value, datetime):
                cell.number_format = numbers.FORMAT_DATE_YYYYMMDD2

        wb.save(file_path)

    except Exception as e:
        print(f"An error occurred while appending data to excel: {e}")

def forced_run_list(file_path, sheet_name):
    try:
        # Read the Excel sheet
        df = pd.read_excel(file_path, sheet_name=sheet_name)

        # Filter rows
        filtered_df = df[(df['Status'] == 'Not Completed')]
        return filtered_df.to_dict(orient='records')
    except Exception as e:
        print(f"Error occurred: {e}")
        return None

def filter_not_completed_rows_from_data(data):
    try:
        # Convert list of dictionaries to DataFrame
        df = pd.DataFrame(data)

        # Filter rows
        filtered_df = df[((df['IRN Status'] != 'Completed') & (df['IRN Status'] != 'No Data')) | (df['Upload Status'] != 'Completed') & (df['Upload Status'] != 'No Data')]
        
        return filtered_df.to_dict(orient='records')
    except Exception as e:
        print(f"Error occurred: {e}")
        return None
    
def filter_table(table, column_name, allowed_values):
    """Filter rows where the specified column matches any allowed values."""
    try:
        if not table:
            raise ValueError("Input table is empty.")
        
        if column_name not in table[0]:
            raise ValueError(f"Column '{column_name}' not found in table.")

        filtered = [row for row in table if row.get(column_name) in allowed_values]
        return filtered

    except Exception as e:
        print(f"Error while filtering table: {e}")
        return [] 

def append_consolidated_excel(source_file, target_file, sheet_name="ConsolidateddSheet"):
    try:
        # Read source Excel (with headers)
        df = pd.read_excel(source_file)

        # If target file exists, append to it
        if os.path.exists(target_file):
            existing_df = pd.read_excel(target_file)
            combined_df = pd.concat([existing_df, df], ignore_index=True)
        else:
            combined_df = df

        # Write combined data to target file
        combined_df.to_excel(target_file, index=False, sheet_name=sheet_name)
        print(f"Data written to: {target_file}")
        return True

    except Exception as e:
        print(f"Error while copying/appending Excel data: {e}")
        return False
    
def format_excel_headers(file_path):
    try:
        wb = load_workbook(file_path)

        for sheet in wb.worksheets:
            column_widths = {}

            for row in sheet.iter_rows():
                for cell in row:
                    # Track max width of content for each column
                    if cell.value:
                        col_letter = cell.column_letter
                        cell_length = len(str(cell.value))
                        column_widths[col_letter] = max(column_widths.get(col_letter, 0), cell_length)

            for cell in sheet[1]:  # First row (headers)
                cell.font = Font(bold=True)
                cell.alignment = Alignment(horizontal="center", vertical="center")

            # Set column widths
            for col_letter, width in column_widths.items():
                sheet.column_dimensions[col_letter].width = width + 2  # add padding

        wb.save(file_path)
        print(f"Headers formatted and columns auto-fitted in: {file_path}")
        return True

    except Exception as e:
        print(f"Error: {e}")
        return False