# drcensor.bash

A quick-and-dirty script for detecting website censorship methods.

## Usage

`bash drcensor.bash HOST [OPTIONAL_TIMEOUT]`

## Steps to Run For The Layman

**Note: Windows 10 users will need to install WSL and Ubuntu on it—see https://www.computerhope.com/issues/ch001879.htm**

1. Download the script file
2. Place the script file on Desktop
3. Open terminal/CMD
4. In the terminal, type the following: `cd Desktop`
5. Then type `bash drcensor.bash example.com | tee output` (replace `example.com` with the site you want to test) 
6. The output that follows will be useful in cases of failure (which will be shown in red)
