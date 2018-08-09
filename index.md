---
title: Amazon Ion
description: "Amazon Ion is a richly-typed, self-describing, hierarchical data serialization format offering interchangeable binary and text representations. Ion was built to address rapid development, decoupling, and efficiency challenges faced every day while engineering large-scale, service-oriented architectures. Ion has been addressing these challenges within Amazon for nearly a decade, and we believe others will benefit as well."
---

Amazon Ion is a [richly-typed][13], [self-describing][15], hierarchical data serialization
format offering [interchangeable binary and text][14] representations. The [text format][10]
(a superset of [JSON][1]) is easy to read and author, supporting rapid
prototyping. The [binary representation][11] is [efficient to store, transmit, and
skip-scan parse][16].  The rich type system provides unambiguous semantics for
long-term preservation of business data which can survive multiple generations
of software evolution.

**Available Libraries:** [Ion Java][3] -- [Ion C][4] -- [Ion Python][5] -- [Ion JavaScript][6]

<br/>

### Latest News

---
{% for post in site.posts limit:2 %}
  **<a href="{{site.baseurl}}{{post.url}}">{{ post.title }}</a>**<br/>
  *{{post.date | date_to_long_string}}*<br/>
  {{post.content}}
{% endfor %}
---
Visit the [News][7] page for more announcements about Amazon Ion.

<br/>

### Ion Text Example {#example}
<!-- commented out until we create a pygment parser for Ion
```json-doc
/* Ion supports comments. */
// Here is a struct, which is similar to a JSON object.
{
  // Field names don't always have to be quoted.
  name: "fido",

  // This is an integer with a user annotation of 'years'.
  age: years::4,

  // This is a timestamp with day precision.
  birthday: 2012-03-01T,

  // Here is a list, which is like a JSON array.
  toys: [
    // These are symbol values, which are like strings,
    // but get encoded as integers in binary.
    ball,
    rope
  ],
}
```
-->
<!-- 
To generate:
1. Uncomment the json-doc code block above
2. Run Jekyll locally (jekyll serve)
3. Navigate to the index page in a browser and inspect the code
4. Copy the generated html over the html below
5. Find and replace any instance of err with na
6. Comment out the code block above
 -->
<div class="language-json-doc highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="c">/* Ion supports comments. */</span><span class="w">
</span><span class="c1">// Here is a struct, which is similar to a JSON object.</span><span class="w">
</span><span class="p">{</span><span class="w">
  </span><span class="c1">// Field names don't always have to be quoted.</span><span class="w">
  </span><span class="na">name</span><span class="p">:</span><span class="w"> </span><span class="s2">"fido"</span><span class="p">,</span><span class="w">

  </span><span class="c1">// This is an integer with a user annotation of 'years'.</span><span class="w">
  </span><span class="na">age</span><span class="p">:</span><span class="w"> </span><span class="na">years</span><span class="p">::</span><span class="mi">4</span><span class="p">,</span><span class="w">

  </span><span class="c1">// This is a timestamp with day precision.</span><span class="w">
  </span><span class="na">birthday</span><span class="p">:</span><span class="w"> </span><span class="mi">2012-03-01</span><span class="mi">T</span><span class="p">,</span><span class="w">

  </span><span class="c1">// Here is a list, which is like a JSON array.</span><span class="w">
  </span><span class="na">toys</span><span class="p">:</span><span class="w"> </span><span class="p">[</span><span class="w">
    </span><span class="c1">// These are symbol values, which are like strings,</span><span class="w">
    </span><span class="c1">// but get encoded as integers in binary.</span><span class="w">
    </span><span class="na">ball</span><span class="p">,</span><span class="w">
    </span><span class="na">rope</span><span class="w">
  </span><span class="p">],</span><span class="w">
</span><span class="p">}</span><span class="w">
</span></code></pre></div></div>

The [Specification][10] gives an overview of the full list of the core data types. 

<br/>

### More Information

Ion was built to address rapid development, decoupling, and efficiency
challenges faced every day while engineering large-scale, service-oriented
architectures. Ion has been addressing these challenges within Amazon for nearly
a decade, and we believe others will benefit as well.

To find out more about the Ion format and for guides on using it, check out the [Docs][8] page. The [Libs][12] page contains links to the officially supported libraries as well as community supported tools. The [Help][9] page contains information on how to contribute, how to contact the Ion Team, and answers to the frequently asked questions.

<!-- References -->
[1]: http://json.org
[2]: guides/why.html
[3]: https://github.com/amzn/ion-java
[4]: https://github.com/amzn/ion-c
[5]: https://github.com/amzn/ion-python
[6]: https://github.com/amzn/ion-js
[7]: news.html
[8]: docs.html
[9]: help.html 
[10]: docs/spec.html
[11]: docs/binary.html
[12]: libs.html
[13]: guides/why.html#rich-type-system
[14]: guides/why.html#dual-format-interoperability
[15]: guides/why.html#self-describing
[16]: guides/why.html#read-optimized-binary-format