import Data.Maybe (listToMaybe)
import GHC.Internal.System.Environment (getArgs)
import System.Process (callCommand)

runProject :: IO ()
runProject = do
  putStrLn $ "running: " ++ cmd
  buildProject >> callCommand cmd
  where
    cmd = "./image-viewer /home/lw/dotfiles/wallpapers"

buildProject :: IO ()
buildProject = do
  putStrLn $ "running: " ++ cmd
  callCommand cmd
  where
    cmd = "odin build ."

main :: IO ()
main = do
  args <- getArgs
  case listToMaybe args of
    Just arg -> case arg of
      "build" -> buildProject
      "run" -> runProject
      _ -> putStrLn "invalid command"
    Nothing -> putStrLn "please provide a build command"
