# -----------------------GLOBAL WAIT & RETRY FOR ELEMENTS---------------------------#
GLOBAL_RETRY_AMOUNT             = '5x'
SHORT_GLOBAL_RETRY_AMOUNT       = '2x'
GLOBAL_RETRY_INTERVAL           = '20s'
SHORT_GLOBAL_RETRY_INTERVAL     = '8s'
SHORT_WAIT                      = '2s'
MEDIUM_WAIT                     = '5s'
LONG_WAIT                       = '10s'
DEFAULT_WAIT                    = '1s'
MINIMUM_WAIT                    = '0.5s'
EXTRA_LONG_WAIT                 = '60s'
EXTRA_MEDIUM_WAIT               = '15s'
PAGE_LOADING_WAIT               = '4min'
FINAL_LOADING_WAIT              = '8min'


#Common Variable Values
ConfigFile              = r"\Config\Config.xlsx"
DateFormat              = r"%b-%Y"
NormalDateFormat        = r"%d-%m-%Y"
TmlRefNo_Regex          = r"(?<=TML Ref. No. )\d+"
InvoiceCount_Regex      = r"(\d+)"
SearchColumnNamne       = "Reference No"
TrackerSheetName        = "BOTStatus_TrackerDetailed"
BriefTrackerSheet       = 'BOTStatus_Tracker1'
ReportSheetName         = "EndReport_Tracker"
PageLimit               = 100
