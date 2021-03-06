#!/usr/bin/env cwl-runner
#
# Sends score emails to participants
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn18058986/synapsepythonclient:1.9.2

inputs:
  - id: submissionid
    type: int
  - id: synapse_config
    type: File
  - id: results
    type: File
  - id: private_annotations
    type: string[]?
  - id: previous
    type: boolean?

arguments:
  - valueFrom: score_email.py
  - valueFrom: $(inputs.submissionid)
    prefix: -s
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: $(inputs.results)
    prefix: -r
  - valueFrom: $(inputs.private_annotations)
    prefix: -p


requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: score_email.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import os
          parser = argparse.ArgumentParser()
          parser.add_argument("-s", "--submissionid", required=True, help="Submission ID")
          parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
          parser.add_argument("-r", "--results", required=True, help="Resulting scores")
          parser.add_argument("-p", "--private_annotaions", nargs="+", default=[], help="annotations to not be sent via e-mail")

          args = parser.parse_args()
          syn = synapseclient.Synapse(configPath=args.synapse_config)
          syn.login()

          sub = syn.getSubmission(args.submissionid)
          userid = sub.userId
          evaluation = syn.getEvaluation(sub.evaluationId)
          with open(args.results) as json_data:
            annots = json.load(json_data)

          status = annots['leaderboard_prediction_file_status']
          if status == "SCORED":
              del annots['leaderboard_prediction_file_status']
              subject = "Submission to '%s' scored!" % evaluation.name
              if len(annots) == 0:
                  message = "Your submission has been scored."
              else:
                  for annot in args.private_annotaions:
                      del annots[annot]
                  message = ["Hello %s,\n\n" % syn.getUserProfile(userid)['userName'],
                             "Your submission (%s) is scored, below are your results:\n\n" % sub.name,
                             "\n".join([i + " : " + str(annots[i]) for i in annots]),
                             "\n\nSincerely,\nChallenge Administrator"]
              syn.sendMessage(
                  userIds=[userid],
                  messageSubject=subject,
                  messageBody="".join(message),
                  contentType="text")
          
outputs: []