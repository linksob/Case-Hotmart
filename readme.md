![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-1.x-purple?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws&logoColor=white)


# Case Hotmart – AWS Glue ETL com Terraform

Este projeto provisiona e executa um pipeline ETL serverless usando **AWS Glue** e infraestrutura como código com **Terraform**. O objetivo é processar dados de compras, consolidando informações de múltiplas tabelas, aplicando regras de qualidade e salvando o resultado em um bucket S3 particionado.

---

## 🛠️ Stack Utilizada

- **Terraform**: Provisionamento de recursos AWS (Glue, S3, IAM).
- **AWS Glue**: Orquestração e execução do job ETL em Python.
- **AWS S3**: Armazenamento de scripts, logs e dados processados.
- **AWS IAM**: Controle de permissões para execução segura do Glue Job.
- **Python 3 (PySpark)**: Lógica de transformação de dados.
- **CloudWatch Logs**: Monitoramento e logging do Glue Job.

---

## 📂 Estrutura do Projeto

```
Case-Hotmart/
│
├── Ex_2/
│   ├── app/
│   │   └── ex_2_glue_job.py        # Script principal do Glue Job (PySpark)
│   ├── tests/
│   │   └── test_ex_2_glue_job.py   # Testes do script ETL
│   ├── sales.sql                   # respostas do ex 2
│   ├── select_estado_atual.sql     # respostas do ex 2
│   └── select_subsidiary.sql       # respostas do ex 2
│
├── Terraform/
│   └── main.tf                     # Infraestrutura AWS (Glue, S3, IAM)
|   └── output.tf
|   └── provider.tf
|   └── terraform.tfvars
|   └── variables.tf
│
└── readme.md
```

## 🚀 Recursos Provisionados

- **Buckets S3**
  - Scripts do Glue Job
  - Logs e arquivos temporários

- **IAM Role**
  - Permissões para Glue, S3 e CloudWatch

- **AWS Glue Job**
  - Job ETL em Python 3, configurado via Terraform

---

## ⚙️ Como funciona o ETL (`ex_2_glue_job.py`)

1. **Leitura dos dados**: Carrega tabelas de compras, itens e informações extras do catálogo Glue.
2. **Transformação**: Faz joins, merge com histórico, calcula valores diários e mantém apenas o registro mais recente por compra.
3. **Data Quality**: Aplica regras de qualidade (chave primária, tipos, valores mínimos).
4. **Gravação**: Salva o resultado em S3 particionado por data.

---

## 🏗️ Como Usar

1. Configure suas credenciais AWS.
2. Ajuste variáveis no Terraform (`env`, nomes de buckets, etc).
3. Faça o deploy da infraestrutura:

   ```bash
   terraform init
   terraform apply