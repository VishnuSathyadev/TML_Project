#-------------------------------------Login----------------------------------------------------

loc_login_header            = '//div[@id="kc-header-text"]'
loc_login_username          = '//input[@name="username"]'
loc_login_password          = '//input[@name="password"]'
loc_login_button            = '//input[@name="login"]'
loc_invalid_credentials     = '//span[@id="input-error" and contains(text(),"Invalid username or password") ]'
loc_home_page_check         = '//span[text()="NextGen Apps"]'


#-------------------------------------Log Out---------------------------------------------------

loc_direct_home_button      = '//mat-icon[text()="home"]'
loc_profile_icon            = '//mat-icon[text()="account_circle"]'
loc_log_out_button          = '//span[text()="Logout "]'


#------------------------------------Select Positions--------------------------------------------

loc_change_positions        = '//span[text()="Change Position"]'
loc_options_page_check      = '//strong[text()="Select Position"]'
loc_position_save_button    = '//span[text()=" Save "]'
loc_sap_warranty            = '//a[text()="SAP Warranty"]'
loc_menu_bar                = '//mat-icon[text()="menu"]'
loc_sap_warranty_open_check = '//p[text()="Transaction"]'
loc_gst_invoice_option      = '//span[text()="GST Invoice"]'



#---------------------------------------Gst Invoicing----------------------------------

loc_gst_screen_header       = '//a[@class="ui ribbon label" and contains(text(), "GST Invoice Criteria")]'
loc_dealer_code             = '//input[@id="txt_gst_invoice_dealer"]'
loc_month_select            = '//div[@class="ui input left icon"]//input[@name="MonthYear"]'
loc_invoice_type            = '(//div[@class="ui dropdown selection"]//i[@class="dropdown icon"])[1]'
loc_invoice_status          = '(//div[@class="ui dropdown selection"]//i[@class="dropdown icon"])[2]'
loc_search_button           = '//button[text()="Search"]'
loc_pending_with_dealer     = '//div[text()= " Pending With Dealer"]'
loc_ready_to_upload         = '//div[text()= " Ready for Printout / Upload"]'

#---------------------------------------Generation of IRN and GST----------------------------------

loc_generate_irn            = '//button[text()=" Generate IRN and GST Invoice "]'
loc_submit                  = '//div[@class="ui buttons"]//button[contains (text(), "Submit")]'
loc_save_claim_popup        = '//span[text()="Save Claim"]' 
loc_popup_submit            = '//span[text()="Yes"]'
loc_gstirn_close_button     = '//div[@id="modal_invoice_details"]//i[@class="close icon"]'
loc_irn_generated           = '(//table[contains(@id, "pn_id")]//tbody//tr//td[8][normalize-space(text())])[1]'

#---------------------------------------Downloading & Uploading of IRN and GST----------------------------------

loc_filter_frame            = '//object'
loc_no_data_available       = '//td[text()="No Data Available"]'
loc_action_button           = '(//button[@icon="pi pi-pencil"])'
loc_row_one_action_button   = '(//button[@icon="pi pi-pencil"])[1]'
loc_show_dropdown           = '(//div[@class="ui dropdown selection"]//i[@class="dropdown icon"])[3]'
loc_choose_invoice_count    = '//div[@data-value="100"]'
loc_next_page_button        = '(//a[@class="icon item" and contains(text(), "Next")])[1]'
loc_invoice_count           = '//label[contains (text(), "Total Record(s) Found:")]'
loc_tml_ref_no              = '//p[contains(text(), "Invoice Details for TML Ref. No")]'
loc_no_data_wait_download   = '(//td[contains (text(), "No Data Available")])[1]'
loc_irn_no_check            = '(//div[@class="row first-form app-form"]//tr[contains(@class, "ng-star-inserted")]/td[8])[1]'
loc_download_button         = '//button[text()=" Download GST Invoice "]'
loc_download_window         = 'name:"Save As"'
loc_download_path_field     = 'name:"File name:" and path:"1|1|1|6|3|2|1"'
loc_save_button_download    = 'name:"Save"'
loc_documents               = '//div[text()="Documents "]'
loc_upload_screen_check     = '//a[text()="Upload Invoice"]'
loc_choose_file             = '//input[@id="file_invoice_upload"]'
loc_choose_window           = 'name:"Open"'
loc_path_field              = 'name:"File name:" and path:"3|1|1"'
loc_open_button             = 'control:"ButtonControl" and path:"1|5"'
loc_upload_button           = '//button[text()="Upload Document"]'
loc_upload_submit_button    = '//button[@class="ui button green_btn" and contains (text(), "Submit")]'


#---------------------------------------Data Extraction----------------------------------

loc_table_data              = '//table[@role="table"]'


#---------------------------------------Error Handling------------------------------------------------

loc_status_header           = '//div[@data-pc-section="summary"]'
loc_status_message          = '//div[@data-pc-section="detail"]'
loc_status_close_button     = '//button[@aria-label="Close"]'
loc_loader_display          = '//div[@class="loader" and not(contains(@style, "display: none"))]'
loc_loader_invisible_check  = '//div[@class="loader" and contains(@style, "display: none")]'    
loc_first_page_button       = '(//a[contains(text(),"First") and @class="icon item"])[1]'   
loc_first_page_disabled     = '(//a[contains(text(),"First") and @class="icon item disabled"])[1]' 
loc_dropdown_hudread        = '//div[@class="text" and text()="100"]'