---
layout: page
icon: fas fa-code-branch
order: 5
title: Projects
---

{% for project in site.projects %}
### {{ project.title }}

{{ project.excerpt }}

[View Documentation]({{ project.url }}) • [GitHub Repository]({{ project.github_link }})

---
{% endfor %}