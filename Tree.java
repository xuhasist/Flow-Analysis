import moa.classifiers.trees.HoeffdingTree;
import moa.classifiers.Classifier;
import moa.streams.generators.RandomTreeGenerator;
import moa.streams.ArffFileStream;
import moa.core.Measurement;
import moa.core.InstancesHeader;
import weka.core.Instance;
import weka.core.Utils;

import java.io.*;
import java.util.*;

public class Tree {
    public static void main(String[] args) throws IOException {
        ArffFileStream stream = new ArffFileStream("univ1/arff/univ1_all.arff",-1);
        stream.prepareForUse();
        
        Classifier model = new HoeffdingTree();
        model.setModelContext(stream.getHeader());
        model.prepareForUse();

        int TP = 0;
        int FP = 0;
        int FN = 0;
        int TN = 0;

        int isTrueElephant = 0;

        int samplesCorrect = 0;
        int numberSamples = 0;

        //Vector<Integer> elephantFlowIndex = new Vector<Integer>();
        List<String> elephantFlowIndex = new ArrayList<String>();
        while(stream.hasMoreInstances()) {
            Instance trainInst = stream.nextInstance();

            int originalClassIndex = (int) trainInst.classValue();
            int classLabelIndex = Utils.maxIndex(model.getVotesForInstance(trainInst));

            boolean isElephant = false;
            if(classLabelIndex == 0)
                isElephant = true;
            
            if(isElephant) {
                //System.out.println(trainInst);
                elephantFlowIndex.add(String.valueOf(numberSamples));

                if(originalClassIndex == 0)
                    TP++;
                else
                    FP++;
            }
            else {
                if(originalClassIndex == 0)
                    FN++;
                else
                    TN++;
            }

            if(originalClassIndex == 0)
                isTrueElephant++;

            if(originalClassIndex == classLabelIndex) {
                samplesCorrect++;
            }
                
            model.trainOnInstance(trainInst);
            numberSamples++;
        }

        System.out.println(String.join(",", elephantFlowIndex));

        /*
        Iterator it = elephantFlowIndex.iterator();
        while(it.hasNext())
            System.out.println(it.next());
        */
        
        /*
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
        */
    }
}
