import json
from utils.env import load_env
from workflows.example_workflow import run_workflow

def main():
    env = load_env()

    print("[main] Validated environment variables")
    run_workflow(env)

if __name__ == "__main__":
    main()