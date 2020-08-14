---
title: "The making of this site and what I'll be doing with it"
---

<h2>The making</h2>

This site is generated using <a href="https://jaspervdj.hakyll">Hakyll</a>, a static site generator written in Haskell. Previously, I had written my own in very messy C, loosely based on code from <a href="https://suckless.org">suckless.org</a>, but I decided in the process of fiddling with my CSS that I could do with a change of pace.

I am not very familiar with Haskell, so as a basis I have taken heavy inspiration for my <code>site.hs</code> from <a href="https://www.imagination-land.org/">Marc-Antoine Perennou</a> (who in turn 'shamelessly stole' his - apparently - from <a href="http://blog.clement.delafargue.name/posts/2012-10-21-blog-deployment-system.html">Clément Delafargue</a>), and I also went with a CSS template by <a href="https://html5up.net/">HTML5 UP!</a>, because, while I wanted to rewrite mine, it's 35°C, and I quickly lost patience. So, both will form a basis that I will work from, and hopefully I will learn some Haskell and improve my CSS-fu in the process. One of the first things I will do is to add tags and tag pages, but given this is a fluff feature, I won't be rushing.

<h2>What I'll be doing with it</h2>

Well, I'll be blogging, for one thing. Mostly just personal rambles, likely to touch on language and linguistics, tea, software and music; I might do a series of posts on some topics, and will likely put up tutorial-esque documentation of my technological travails. For the second thing, I will be posting some annotated bibliographies about topics that interest me, mostly for personal reference.

<h3>Update August 13, 2020</h2>

After making this post yesterday I ran into an issue making the bibliographies section of the site - that is, having two lists render on a page. I tried a lot of spaghetti code, but in my frustration I eventually made a Stackoverflow post where Li-yao Xia kindly proided the following:

```haskell
create ["index.html"] $ do
        route idRoute
        compile $ do
            let mkposts = postList tags "posts/*" (fmap (take 10) . recentFirst)
                mkbibs = bibList tags "bibs/*" (fmap (take 10) . recentFirst)
                homeCtx' = field "posts" (const mkposts)  -- Populate the context with those fields
                        <> field "bibs" (const mkbibs)    --
                        <> homeCtx
            makeItem ""  -- This doesn't matter since the next template does not contain "body" (after renaming it to "posts")
                >>= loadAndApplyTemplate "templates/index.html"   homeCtx'  -- This template mentions "posts" and "bibs", which will be looked up in homeCtx'
                >>= loadAndApplyTemplate "templates/default.html" homeCtx'
                >>= relativizeUrls
```


Suffice to say, I was surprised by how simple this was, and now know I'll have to study quite a bit more Haskell if I want to maintain this site.

Also, if you know of a CSS-only syntax highlighter that supports haskell, ping me an email - I have the site setup to use prism for when/if I eventually migrate to private hosting, but the JS doesn't work with GithubPages.
