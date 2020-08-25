provider "google" {
  credentials = file("account.json")
  project     = var.project
  region      = var.region
 
}

resource "google_logging_folder_sink" "my-sink" {
  name   = "my-sink"
  folder = google_folder.my-folder.name

  # Can export to pubsub, cloud storage, or bigquery
  destination = "storage.googleapis.com/${google_storage_bucket.log-bucket.name}"

  # Log all WARN or higher severity messages relating to instances
  filter = "resource.type = gce_instance AND severity >= WARN"
}

resource "google_storage_bucket" "log-bucket" {
  name = "folder-loggingnewn-buckets"
}

resource "google_project_iam_binding" "log-writer" {
  role = "roles/storage.objectCreator"

  members = [
    google_logging_folder_sink.my-sink.writer_identity,
  ]
}
resource "google_logging_project_sink" "default" {
  name                   = "nginx-logs"
  destination            = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.default.dataset_id}"
  filter                 = "resource.type = gce_instance AND logName = projects/${var.project}/logs/nginx-access"
  unique_writer_identity = true
}

resource "google_project_iam_binding" "default" {
  role = "roles/bigquery.dataEditor"

  members = [
    google_logging_project_sink.default.writer_identity,
  ]
}


