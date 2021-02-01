{-# LANGUAGE NumericUnderscores #-}

module Main where

import Control.Concurrent (threadDelay)
import Control.Monad (forever, when, zipWithM_)
import System.Directory (
    createDirectory,
    doesDirectoryExist,
    getCurrentDirectory,
    listDirectory,
    removeDirectoryRecursive,
    setCurrentDirectory,
 )
import System.Environment (getArgs)
import System.FSNotify (watchTree, withManager)
import System.IO (BufferMode (LineBuffering), hFlush, hSetBuffering, stdout)
import System.Random (Random (randoms), newStdGen)


main :: IO ()
main = do
    args <- getArgs
    case args of
        ["watcher"] -> do
            dirToWatch <- getCurrentDirectory
            putStrLn $ "Watching directory " <> dirToWatch
            hSetBuffering stdout LineBuffering
            withManager $ \mgr -> do
                _ <- watchTree mgr dirToWatch (const True) $ \event -> do
                    print event
                    hFlush stdout
                forever $ threadDelay 1_000_000
        ["generator"] -> do
            exists <- doesDirectoryExist "tmp"
            when exists $ removeDirectoryRecursive "tmp"
            createDirectory "tmp"
            setCurrentDirectory "tmp"
            gen <- newStdGen
            let rbools = randoms gen
            zipWithM_ createOrDeleteFile rbools [1 .. 100_000]
        _ -> print "Usage: fsnotify-reproducer (watcher|generator)"


createOrDeleteFile :: Bool -> Int -> IO ()
createOrDeleteFile True i = do
    putStrLn $ show i <> " Create"
    createDirectory (show i)
    writeFile (show i <> "/file.txt") "test"
    threadDelay 10_000 -- 0.01s
createOrDeleteFile False i = do
    dirs <- listDirectory "."
    case dirs of
        [] -> pure ()
        (d : _) -> do
            putStrLn $ show i <> " Delete"
            removeDirectoryRecursive d
