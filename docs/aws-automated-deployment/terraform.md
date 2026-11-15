# TERRAFORM BOOTSTRAP

`terraform/bootstrap` klasörü tek bir iş yapıyor: GitHub Actions'ın AWS'ye bağlanırken kullanacağı IAM rolünü oluşturuyor. Bunu da ben localimden çalıştırdım. 

- Github AWS'e token üreterek OIDC ile güven ilişkisi kuruyor.

```hcl
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
```

- `url`: GitHub'ın token ürettiği adres. AWS bu adrese güvenmeyi öğreniyor.
- `client_id_list`: Token'ın kimin için üretildiği. AWS için her zaman `sts.amazonaws.com`.


>Rolün iki koşulu var. İkisi de tutmazsa AWS rolü vermez.

```hcl
condition {
  test     = "StringEquals"
  variable = "token.actions.githubusercontent.com:aud"
  values   = ["sts.amazonaws.com"]
}

condition {
  test     = "StringEquals"
  variable = "token.actions.githubusercontent.com:sub"
  values   = local.allowed_subs
}
```

- `aud`: Token AWS için mi üretilmiş.
- `sub`: Token hangi repodan ve hangi branch'ten geliyor.

`sub` için iki farklı yazım kabul ediyoruz:

```
repo:cheriladyy/automated-deployment:ref:refs/heads/main
repo:cheriladyy@158853286/automated-deployment@1454130753:ref:refs/heads/main
```

> İkinci yazım neden var: Rolü alamadığım için. CloudTrail'de baktığımda GitHub'ın `sub` değerini ID'lerle birlikte gönderdiğini gördüm. O yüzden ikisini de ekledim.

- Sadece `main` branch'i izinli. Başka bir branch'ten çalışan workflow bu rolü alamaz. 

Owner ve repo ID'lerini bulmak için:

```bash
curl -s https://api.github.com/repos/cheriladyy/automated-deployment | grep -E '"id"' | head -2
```

İlk `id` repo ID'si, `owner` altındaki `id` owner ID'si. Bu değerler `terraform.tfvars` dosyasında duruyor.

Apply ettiğimde rolün ARN'sini GitHub'da `AWS_ROLE_ARN` secret'ı olarak girdim.

```bash
terraform output terraform_deployer_role_arn
```

## Role yeni izin eklemek - Önemli

`core`'a yeni bir kaynak eklediğinde önce role o izni vermen gerekiyor. Yoksa workflow `AccessDenied` hatası verecek.

1. `terraform/bootstrap/main.tf` dosyasını aç.
2. `data "aws_iam_policy_document" "terraform_deployer"` bloğunun içine yeni bir `statement` ekle ve apply et.


# TERRAFORM CORE

`terraform/core` asıl altyapıyı kuruyor: ağ, sunucu ve Jenkins. Bu klasörü GitHub Actions uyguluyor.

### SSH key

Terraform bir key çifti üretiyor. Public key EC2'ya konuyor, private key Secrets Manager'da `ec2-host-ssh-private-key-dev` adıyla saklanıyor.



### user_data

`user_data`, sunucu ilk açıldığında bir kere çalışan script. Manual kurulumun tamamını bu script yapıyor.


> ÖNEMLİ: Kodda `user_data_replace_on_change = true` var. `user_data`'da tek bir karakter bile değiştirirsen Terraform sunucuyu silip yeniden kurar. Jenkins'teki job'lar ve credential'lar gider, IP adresi değişir. Değiştirmeden önce lokalde `terraform plan` çalıştır ve `must be replaced` yazıyor mu bak.

## 5. Değişkenler


`terraform.tfvars`: Proje adı, region, CIDR'lar 
`local.auto.tfvars`: SSH ve Jenkins için izinli IP'ler 

IP adreslerini repoya koymuyoruz. Lokalde çalışırken örnek dosyayı kopyala:

```bash
cd terraform/core
cp local.auto.tfvars.example local.auto.tfvars
```

İçine kendi IP'ni yaz.:

```hcl
ec2_allowed_ssh_cidrs = ["<ip-adresin>/32"]
jenkins_allowed_cidrs = ["<ip-adresin>/32"]
```

IP'ni öğrenmek için:

```bash
curl -4 -s ifconfig.me
```

# TERRAFORM ENVIRONMENTS

Bu klasör kendi tfvars ve statei olan sabit ortamlar oluşturmuyor. Bu projede kaç ortam açılacağı dinamik şekilde Jenkins üzerinden yapılıyor.

Bu sebeple tek bir klasör üzerinden farklı parametreler ile state key ile ilerleyeceğiz. 

Her ortamın state'i ayrı olacağı için terraform apply/destroy çalıştırılması  sadece o dosyadaki kaynakları etkileyecek.

Bunun için de backend.tf içinde sabit key yazmıyoruz. Jenkins her çalıştığında key'i kendisi veriyor:

>terraform init -backend-config="key=automated-deployment/environments/example/terraform.tfstate"

Daha detaylı bilgi için: [https://developer.hashicorp.com/terraform/language/backend#command-line-key-value-pairs](https://developer.hashicorp.com/terraform/

## main.tf

```hcl
resource "time_static" "created" {}

locals {
    expires_at = timeadd(time_static.created.rfc399, "${var.ttl_days * 24}h")
}
````
`time_static` ortamın oluşturulma anını sabitler. Expiration date belirlemen için önce ne zaman oluşturulduğunu bilmen lazım :)
 This prevents differences caused by using the timestamp() function.

 ```hcl
 data "terraform_remote_state" "core"`
 ````
 block'u hakkında:
  
  - Coru'un outputs.tf'indeki kaynakları kullanabilmek için data bloğu eklemen gerekiyor. 
  - Terraform'da iki tür blok var: `resource` ve `data`. data sadece okur ama resource oluşturur, değiştirir, siler.
  - Sadece core'un state dosyasındaki output değerini okuyor ve sadece outputs.tf'de tanımlı olanlar okunuyor.

  Daha fazla bilgi için: https://developer.hashicorp.com/terraform/language/state/remote-state-data

  > `data "aws_ami" "ubuntu"` kısmı ise direkt AWS'nin EC2 API'sinden okunuyor.

  Daha fazla bilgi için: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

Sürekli kafanı karıştıran bir durum: 

```hcl
resource "aws_security_group" "env"
````
Burdaki env sadece kod içinde kullandığımız resource'un etiketi başka hiçbir anlamı yok. 

-target ile apply yaparken çağırıyorsun bide şöyle: `-target=...aws_security_group.env` gibi

```hcl
resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each = toset([for p in local.template_ports[var.template] : tostring(p)])

  security_group_id = aws_security_group.env.id
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = "0.0.0.0/0"
}
```
- locals.tf dosyasında belirlediğimiz template'e göre sg ingress portlarını açıyor. Kod içinde tekrar tekrar kullanacağın değerlere isim verdiğin kısım. 
- local.template_ports[var.template] → local.template_ports["fullstack"] → [80, 5432]
- for_each her eleman için bir kural oluşturuyor 
- template: webserver, database veya fullstack olabilir.
- each.value her turda o elemanı veriyor. tonumber ile tekrar sayıya çevrilip from_port ve to_port alanlarına yazılıyor.
- local.template_ports["fullstack"] ise [80, 5432] döndürüyor, yani bir sayı listesi.

Daha fazla bilgi için: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each

Test etmek için: 

```hcl
terraform init -backend-config="key=automated-deployment/environments/test-web/terraform.tfstate"

cd /environments && terraform plan -var env_name=test-web -var template=webserver -var size=small -var ttl_days=1
````
