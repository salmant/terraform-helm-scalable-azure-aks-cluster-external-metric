import os
from python_terraform import Terraform

TF_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def test_required_terraform_files_exist():
    """
    Verify that the main Terraform files required for the AKS autoscaling
    deployment are present in the repository.
    """
    required_files = [
        "aks_cluster.tf",
        "variables.tf",
        "outputs.tf",
        "k8s_resources.tf",
        "sb_queue.tf",
        "init.tf",
        "locals.tf",
    ]

    for file_name in required_files:
        file_path = os.path.join(TF_DIR, file_name)
        assert os.path.exists(file_path), f"{file_name} is missing"


def test_terraform_validate():
    """
    Run terraform validate to check the Terraform configuration syntax.

    This test does not run terraform apply and does not create any Azure resources.
    """
    tf = Terraform(working_dir=TF_DIR)
    return_code, stdout, stderr = tf.validate()

    assert return_code == 0, f"Terraform validation failed: {stderr}"
