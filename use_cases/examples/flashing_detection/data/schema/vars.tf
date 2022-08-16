variable "PROJECT_ID" {
	type		= string
	description	= "The GCP project name to use for your flashing reporting schema"
}

variable "REGION_NAME" {
	type		= string
	description	= "The GCP region in which to populate the sample flashing report data"
	default		= "us-central1"
}

variable "MARKET_DATA_DATASET" {
	type		= string
	description	= "The dataset name that will store the market data"
	default		= "market_data"
	nullable    = false
}

variable "ORDER_DATA_DATASET" {
	type		= string
	description	= "The dataset name that will store the order data"
	default		= "order_data"
	nullable    = false
}
