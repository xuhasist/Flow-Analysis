import weka.core.Instances;
import weka.classifiers.Evaluation;
import weka.classifiers.trees.J48;
import weka.core.converters.ConverterUtils.DataSource;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;

import java.io.*;
import java.util.*;

public class DecisionTree {
    public static void main(String[] args) throws Exception {                              
        DataSource source = new DataSource("univ1/arff/univ1_all.arff");
        Instances data = source.getDataSet();
        data.setClassIndex(data.numAttributes() - 1);
        
        String[] options = new String[1];
        options[0] = "-U";            // unpruned tree
        J48 tree = new J48();         // new instance of tree
        tree.setOptions(options);     // set the options
        tree.buildClassifier(data);   // build classifier
        
        // evaluate classifier and print some statistics
        //Evaluation eval = new Evaluation(train);
        //eval.evaluateModel(tree, test);
        //System.out.println(eval.toSummaryString("\nResults\n======\n", false));
        
        int TP = 0;
        int FP = 0;
        int FN = 0;
        int TN = 0;
        
        int isTrueElephant = 0;

        int samplesCorrect = 0;
        int numberSamples = 0;
        
        List<String> elephantFlowIndex = new ArrayList<String>();

        for(int i = 0; i < data.numInstances(); i++) {
            double originalClassIndex = data.instance(i).classValue();
            double classLabelIndex = tree.classifyInstance(data.instance(i));
            
            boolean isElephant = false;
            if(classLabelIndex == 0.0)
                isElephant = true;
            
            if(isElephant) {
                elephantFlowIndex.add(String.valueOf(numberSamples));

                if(originalClassIndex == 0.0)
                    TP++;
                else
                    FP++;
            }
            else {
                if(originalClassIndex == 0.0)
                    FN++;
                else
                    TN++;
            }
            
            if(originalClassIndex == 0.0)
                isTrueElephant++;

            if(originalClassIndex == classLabelIndex) {
                samplesCorrect++;
            }
            
            numberSamples++;
        }
        
        //System.out.println(String.join(",", elephantFlowIndex));
        
            
        double precision = ((double)TP/((double)TP+(double)FP));
        double recall = ((double)TP/((double)TP+(double)FN));
        double accuracy = 2*((precision*recall)/(precision+recall));

        System.out.println("numberSamples: " + numberSamples);
        System.out.println("isTrueElephant: " + isTrueElephant);
        System.out.println();
        
        System.out.println("TP: " + TP);
        System.out.println("FP: " + FP);
        System.out.println("FN: " + FN);
        System.out.println("TN: " + TN);
        System.out.println("precision: " + precision);
        System.out.println("recall: " + recall);
        System.out.println("accuracy: " + accuracy);

        System.out.println();
        double _accuracy = 100.0 * (double)samplesCorrect / (double)numberSamples;
        System.out.println(numberSamples + " instances processed with " + _accuracy + "% accuracy");
        
    }    
}
