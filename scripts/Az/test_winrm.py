import winrm
import sys

ip = sys.argv[1]
username = sys.argv[2]
password = sys.argv[3]

try:
    # Créer la session WinRM
    session = winrm.Session(f'http://{ip}:5985/wsman', auth=(username, password), transport='basic', server_cert_validation='ignore')
    result = session.run_cmd('hostname')  # Exemple de commande WinRM
    print(f"Commande exécutée avec succès : {result.std_out.decode()}")
except Exception as e:
    print(f"Erreur de connexion WinRM : {e}")
    sys.exit(1)
