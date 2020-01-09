#! /usr/bin/env python3
import pandas as pd

template = pd.read_csv("/test/template.csv")
template.fillna(2, inplace=True)
print(template)
template.to_csv("/output/predictions.csv",index=False)
