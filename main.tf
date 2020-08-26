provider "google" {
  
  access_token = "ya29.a0AfH6SMCCFXKM3ZUrQffjJdqdWJWh6m560mTMsTjyx84nWj10DCQcyVcZfl6Yqcsq2OCMZb9QBPVTC9U65GKFknm41SUod-S_0wwRkdpW1vi0FZce7LJsKQ0RSpa3sMRTiKP4ZFNPGXcoNiQmEsMtESlGWc3AFaOgh6QAeGZzZAEy9rWeHiBxkcCYhnpTqu6HZIbrz5Pev1PDadNtK9C9ElkW1p-LQJU-Cy0GT_x2osworxCAIPPPqSaaRUtfmHDbXTQCPf0l8PG58g"
  project     = var.project
  region      = var.region
}

data "template_file" "default" {
  template = file("scripts/install.sh")
}

resource "google_compute_firewall" "default" {
  name    = "nginixnew-firewall"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

  source_tags = ["web"]
}

resource "google_compute_network" "default" {
  name = "niginxnew-network"
}


resource "google_compute_instance" "default" {
  name         = "nginxnew"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  tags = ["nginx"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  metadata_startup_script = data.template_file.default.rendered

  service_account {
    scopes = ["logging-write"]
  }
}

resource "google_bigquery_dataset" "default" {
  dataset_id  = "nginxnew_log"
  description = "Nginx Access Logs"
  location    = "US"
}

resource "google_logging_project_sink" "default" {
  name                   = "nginxnew-logs"
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
