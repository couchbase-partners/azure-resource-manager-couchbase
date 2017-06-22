import sys
import yaml
import json

def main():
    filename=sys.argv[1]
    print('Using parameter file: ' + filename)

    with open(filename, 'r') as stream:
        parameters = yaml.load(stream)

    print('Parameters: ' + str(parameters))

    template={}

    file = open('generatedTemplate.json', 'w')
    file.write(json.dumps(template))
    file.close()

main()
