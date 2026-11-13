---
title: Hello, blog
date: 2026-11-13
summary: A sample post that shows how this blog is built and what Markdown it supports.
---

This is a sample post. Replace it with your own writing, or delete the file.

## How a post gets published

1. Add a `.md` file under `app/blog/posts/`.
2. Start it with a front matter block: `title`, `date` and an optional `summary`.
3. Push to `main`. Jenkins rebuilds the image and the post goes live.

The Markdown is converted to HTML **while the Docker image is built**, so the
browser only ever receives plain HTML.

## What Markdown can do

Text can be **bold**, *italic* or `inline code`, and it can
[link to other pages](/#projects).

> Blockquotes are useful for notes and call-outs.

Code blocks keep their formatting:

```hcl
resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

Tables work too:

| Tool      | Used for             |
| --------- | -------------------- |
| Terraform | Infrastructure       |
| Jenkins   | Building the site    |
| Docker    | Packaging and deploy |
