## Writing A Blog

Under /content/blog create a new markdownfile of any name, lets say myBlog.md

Add the following as a starting point

```
    ---  
    title: "My Blog Title"  
    type: "featured"
    description: "My Blog Description"
    draft: false
    ---
```
---

The type should be featured or regular, featured posts will always appear on the blog landing page.

**NOTE**
Setting draft to false means you can push it to the website view it but it won't appear on the blog landing page, you could access this via //blog/myBlog

---

You can also add an image by adding the image under static/images and adding.

```
    image: "images/logo.png"
```

You can then write your blog using markdown, this will be converted at compile time to html.

---
**NOTE**
The first paragraph is what is shown on the Blog landing page so make it short and succinct
---

You can add a youtube video by adding the following
```
    {{< youtube C0DPdy98e4c >}}
```
