| Name | Latest Version | Repository | Documentation |
|------|----------------|------------|---------------|
{% assign libraries = site.data.libraries | where: "category", library_type | sort: "name"  -%}
{%- for row in libraries -%}
  {%- assign name = row["name"] -%}
  {%- capture release -%}
    {%- if row["latest_release_version"] -%}
      [{{ row["latest_release_version"] }}](https://github.com/amzn/{{ name }}/releases/latest) ({{ row["latest_release_date"] | date: "%B %d, %Y" }})
    {%- else -%}
      in development
    {%- endif -%}
  {%- endcapture -%}
  {%- capture documentation -%}
    {%- if row["documentation"] -%}
      [Link]({{ row["documentation"] }})
    {%- else -%}
      -
    {%- endif -%}
  {%- endcapture -%}
  {%- capture repository -%}
    [Link](https://github.com/amzn/{{ name }})
  {%- endcapture -%}
  | {{ name }} | {{ release }} | {{ repository }} | {{ documentation }}
{% endfor %}
