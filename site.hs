{-# LANGUAGE OverloadedStrings, TupleSections #-}

module Main where

import Control.Monad (liftM)
import Data.List   (stripPrefix, sortBy)
import Data.Maybe  (fromMaybe)
import Data.Ord (comparing)
import System.FilePath.Posix (takeBaseName, dropExtensions, splitDirectories)
import qualified Data.Map as M
import Data.Default (Default (..))
import Hakyll
import qualified Text.Pandoc as Pandoc
-- Custom configuration

configuration :: Configuration
configuration = defaultConfiguration
    { tmpDirectory  = "/tmp/hakyll"
    }

-- Contexts

defaultCtx :: Context String
defaultCtx = dateField "date" "%B %e, %Y" <> defaultContext

basicCtx :: String -> Context String
basicCtx title = constField "title" title <> defaultCtx

homeCtx :: Context String
homeCtx = basicCtx "Home"

allPostsCtx :: Context String
allPostsCtx = basicCtx "All posts"

allBibsCtx :: Context String
allBibsCtx = basicCtx "Bibliographies"

feedCtx :: Context String
feedCtx = bodyField "description" <> defaultCtx

tagsCtx :: Tags -> Context String
tagsCtx tags = tagsField "prettytags" tags <> defaultCtx

postsCtx :: String -> String -> Context String
postsCtx title list = constField "body" list <> basicCtx title

bibsCtx :: String -> String -> Context String
bibsCtx title list = constField "body2" list <> basicCtx title

-- Feed configuration

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle       = "Ash's Site"
    , feedDescription = ""
    , feedAuthorName  = "Ashley Price"
    , feedAuthorEmail = "amprice@mailbox.org"
    , feedRoot        = "https://ashprice.github.io/"
    }

-- Auxiliary compilers

externalizeUrls :: String -> Item String -> Compiler (Item String)
externalizeUrls root item = return $ withUrls ext <$> item
    where
        ext x = if isExternal x then x else root ++ x

unExternalizeUrls :: String -> Item String -> Compiler (Item String)
unExternalizeUrls root item = return $ withUrls unExt <$> item
    where
        unExt x = fromMaybe x $ stripPrefix root x

postList :: Tags -> Pattern -> ([Item String] -> Compiler [Item String]) -> Compiler String
postList tags pattern preprocess' = do
    postItemTpl <- loadBody "templates/postitem.html"
    posts <- preprocess' =<< loadAll pattern
    applyTemplateList postItemTpl (tagsCtx tags) posts

bibList :: Tags -> Pattern -> ([Item String] -> Compiler [Item String]) -> Compiler String
bibList tags pattern preprocess' = do
    postItemTpl <- loadBody "templates/postitem.html"
    posts <- preprocess' =<< loadAll pattern
    applyTemplateList postItemTpl (tagsCtx tags) posts

alphaOrder :: [Item a] -> Compiler [Item a]
alphaOrder items = return $
    sortBy (comparing (takeBaseName . toFilePath . itemIdentifier)) items

-- Main

main :: IO ()
main = hakyllWith configuration $ do
    -- Build tags
    tags <- buildTags "posts/*" $ fromCapture "tags/*.html"
    let tagsCtx' = tagsCtx tags

    -- Compress CSS
    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- Copy files and images
    match ("files/*" .||. "files/*/*" .||. "files/*/*/*" .||. "images/*" .||. "images/*/*" .||. "images/*/*/*" .||. "assets/*" .||. "assets/*/*" .||. "assets/*/*/*") $ do
        route   idRoute
        compile copyFileCompiler

    -- Copy favicon, htaccess...
    match "data/*" $ do
        route   $ gsubRoute "data/" $ const ""
        compile copyFileCompiler

    -- Render posts
    match "posts/*" $ do
        route   $ setExtension ".html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"     tagsCtx'
            >>= (externalizeUrls     $ feedRoot feedConfiguration)
            >>= saveSnapshot         "content"
            >>= (unExternalizeUrls   $ feedRoot feedConfiguration)
            >>= loadAndApplyTemplate "templates/not-index.html" tagsCtx'
            >>= loadAndApplyTemplate "templates/default.html"  tagsCtx'
            >>= relativizeUrls

            -- Render bibs
    match "bibs/*" $ do
        route $ setExtension ".html"
        compile $ pandocCompilerWith defaultHakyllReaderOptions withToc
            >>= loadAndApplyTemplate "templates/post.html" tagsCtx'
            >>= (externalizeUrls $ feedRoot feedConfiguration)
            >>= saveSnapshot "content"
            >>= (unExternalizeUrls $ feedRoot feedConfiguration)
            >>= loadAndApplyTemplate "templates/not-index.html" tagsCtx'
            >>= loadAndApplyTemplate "templates/default.html" tagsCtx'
            >>= relativizeUrls

    -- Render posts list
    create ["posts.html"] $ do
        route idRoute
        compile $ do
            list <- postList tags "posts/*" recentFirst
            makeItem list
                >>= loadAndApplyTemplate "templates/posts.html"   allPostsCtx
                >>= loadAndApplyTemplate "templates/not-index.html" allPostsCtx
                >>= loadAndApplyTemplate "templates/default.html" allPostsCtx
                >>= relativizeUrls

    -- Render bibs list
    create ["bibs.html"] $ do
        route idRoute
        compile $ do
            list <- bibList tags "bibs/*" alphaOrder
            makeItem list
                >>= loadAndApplyTemplate "templates/posts.html" allBibsCtx
                >>= loadAndApplyTemplate "templates/not-index.html" allBibsCtx
                >>= loadAndApplyTemplate "templates/default.html" allBibsCtx
                >>= relativizeUrls

    -- Index
    create ["index.html"] $ do
        route idRoute
        compile $ do
            let mkposts = postList tags "posts/*" (fmap (Prelude.take 10) . recentFirst)
                mkbibs = bibList tags "bibs/*" (fmap (Prelude.take 10) . alphaOrder)
                homeCtx' = field "posts" (const mkposts)
                    <> field "bibs" (const mkbibs)
                    <> homeCtx
            makeItem ""
                >>= loadAndApplyTemplate "templates/index.html"   homeCtx'
                >>= loadAndApplyTemplate "templates/default.html" homeCtx'
                >>= relativizeUrls

    -- Post tags
        tagsRules tags $ \tag pattern -> do
            route idRoute
            compile $ do
                list <- postList tags pattern recentFirst

                let title       = "Posts tagged '" ++ tag ++ "'"
                let defaultCtx' = basicCtx title
                let postsCtx'   = postsCtx title list

                makeItem ""
                    >>= loadAndApplyTemplate "templates/posts.html"   postsCtx'
                    >>= loadAndApplyTemplate "templates/not-index.html" defaultCtx'
                    >>= loadAndApplyTemplate "templates/default.html" defaultCtx'
                    >>= relativizeUrls

        -- Render RSS feed
        create ["rss.xml"] $ do
            route idRoute
            compile $ do
                loadAllSnapshots "posts/*" "content"
                    >>= recentFirst
                    >>= renderRss feedConfiguration feedCtx


    -- Read templates
    match "templates/*" $ compile templateCompiler
    where
        withToc = defaultHakyllWriterOptions
            { Pandoc.writerTableOfContents = True
            , Pandoc.writerTemplate        = Just tocTemplate
            }

        -- When did it get so hard to compile a string to a Pandoc template?
        tocTemplate =
            either error id $ either (error . show) id $
            Pandoc.runPure $ Pandoc.runWithDefaultPartials $
            Pandoc.compileTemplate "" "<section style=\"margin-bottom: 2em;\" class=\"toc\">$toc$</section>$body$"
