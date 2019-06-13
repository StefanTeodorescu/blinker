import argparse
import os
import random
import subprocess

BLINKER_CHALLENGES_DIR = "./challenges"

challenges = [
    'SimpleBof'
]

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--dummy',
      type=str,
      help='Dummy',
      default='dummy'
  )
  args = parser.parse_args()

  chall = random.choice(challenges)

  my_env = os.environ.copy()
  my_env['BLINKER_CHALLENGES_DIR'] = BLINKER_CHALLENGES_DIR
  p = subprocess.Popen(['blinker', chall], env=my_env)
  p.wait()

if __name__ == '__main__':
  main()
