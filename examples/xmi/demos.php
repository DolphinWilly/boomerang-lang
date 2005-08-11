<?

$demogroupname = "Xmi";

##############################################################################

# ---------------------------------------------------------
$demo["instructions"] = <<<XXX

This one is not very convenient for a web demo.

XXX;
# ---------------------------------------------------------
$demo["r1"] = <<<XXX
<?xml version="1.0" encoding="UTF-8"?>
<XMI xmi.version="1.0">
  <XMI.header>
    <XMI.documentation>
      <XMI.exporter>Novosoft UML Library</XMI.exporter>
      <XMI.exporterVersion>0.4.20</XMI.exporterVersion>
    </XMI.documentation>
    <XMI.metamodel xmi.name="UML" xmi.version="1.3"/>
  </XMI.header>
  <XMI.content>
    <Model_Management.Model xmi.id="xmi.1" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-8000">
      <Foundation.Core.ModelElement.name>myModel</Foundation.Core.ModelElement.name>
      <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
      <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
      <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
      <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
      <Foundation.Core.Namespace.ownedElement>
        <Foundation.Core.Class xmi.id="xmi.2" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7ffc">
          <Foundation.Core.ModelElement.name>MyClass</Foundation.Core.ModelElement.name>
          <Foundation.Core.ModelElement.visibility xmi.value="public"/>
          <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
          <Foundation.Core.Class.isActive xmi.value="false"/>
          <Foundation.Core.ModelElement.namespace>
            <Foundation.Core.Namespace xmi.idref="xmi.1"/>
          </Foundation.Core.ModelElement.namespace>
          <Foundation.Core.Classifier.feature>
            <Foundation.Core.Attribute xmi.id="xmi.3" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7ff3">
              <Foundation.Core.ModelElement.name>myStaticAttribute</Foundation.Core.ModelElement.name>
              <Foundation.Core.ModelElement.visibility xmi.value="public"/>
              <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
              <Foundation.Core.Feature.ownerScope xmi.value="classifier"/>
              <Foundation.Core.StructuralFeature.multiplicity>
                <Foundation.Data_Types.Multiplicity xmi.id="xmi.4">
                  <Foundation.Data_Types.Multiplicity.range>
                    <Foundation.Data_Types.MultiplicityRange xmi.id="xmi.5">
                      <Foundation.Data_Types.MultiplicityRange.lower>1</Foundation.Data_Types.MultiplicityRange.lower>
                      <Foundation.Data_Types.MultiplicityRange.upper>1</Foundation.Data_Types.MultiplicityRange.upper>
                    </Foundation.Data_Types.MultiplicityRange>
                  </Foundation.Data_Types.Multiplicity.range>
                </Foundation.Data_Types.Multiplicity>
              </Foundation.Core.StructuralFeature.multiplicity>
              <Foundation.Core.StructuralFeature.changeability xmi.value="changeable"/>
              <Foundation.Core.StructuralFeature.targetScope xmi.value="instance"/>
              <Foundation.Core.Attribute.initialValue>
                <Foundation.Data_Types.Expression xmi.id="xmi.6">
                  <Foundation.Data_Types.Expression.language>Java</Foundation.Data_Types.Expression.language>
                  <Foundation.Data_Types.Expression.body></Foundation.Data_Types.Expression.body>
                </Foundation.Data_Types.Expression>
              </Foundation.Core.Attribute.initialValue>
              <Foundation.Core.Feature.owner>
                <Foundation.Core.Classifier xmi.idref="xmi.2"/>
              </Foundation.Core.Feature.owner>
              <Foundation.Core.ModelElement.taggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.7">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>transient</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.3"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.8">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>volatile</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.3"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
              </Foundation.Core.ModelElement.taggedValue>
            </Foundation.Core.Attribute>
            <Foundation.Core.Attribute xmi.id="xmi.9" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7ff0">
              <Foundation.Core.ModelElement.name>myDynamicAttribute</Foundation.Core.ModelElement.name>
              <Foundation.Core.ModelElement.visibility xmi.value="public"/>
              <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
              <Foundation.Core.Feature.ownerScope xmi.value="instance"/>
              <Foundation.Core.StructuralFeature.multiplicity>
                <Foundation.Data_Types.Multiplicity xmi.idref="xmi.4"/>
              </Foundation.Core.StructuralFeature.multiplicity>
              <Foundation.Core.StructuralFeature.changeability xmi.value="changeable"/>
              <Foundation.Core.StructuralFeature.targetScope xmi.value="instance"/>
              <Foundation.Core.Feature.owner>
                <Foundation.Core.Classifier xmi.idref="xmi.2"/>
              </Foundation.Core.Feature.owner>
              <Foundation.Core.ModelElement.taggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.10">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>transient</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.9"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.11">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>volatile</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.9"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
              </Foundation.Core.ModelElement.taggedValue>
            </Foundation.Core.Attribute>
            <Foundation.Core.Operation xmi.id="xmi.12" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fee">
              <Foundation.Core.ModelElement.name>myMethod</Foundation.Core.ModelElement.name>
              <Foundation.Core.ModelElement.visibility xmi.value="public"/>
              <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
              <Foundation.Core.Feature.ownerScope xmi.value="instance"/>
              <Foundation.Core.BehavioralFeature.isQuery xmi.value="false"/>
              <Foundation.Core.Operation.concurrency xmi.value="sequential"/>
              <Foundation.Core.Operation.isRoot xmi.value="false"/>
              <Foundation.Core.Operation.isLeaf xmi.value="false"/>
              <Foundation.Core.Operation.isAbstract xmi.value="false"/>
              <Foundation.Core.Feature.owner>
                <Foundation.Core.Classifier xmi.idref="xmi.2"/>
              </Foundation.Core.Feature.owner>
              <Foundation.Core.BehavioralFeature.parameter>
                <Foundation.Core.Parameter xmi.id="xmi.13" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fed">
                  <Foundation.Core.ModelElement.name>return</Foundation.Core.ModelElement.name>
                  <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
                  <Foundation.Core.Parameter.kind xmi.value="return"/>
                  <Foundation.Core.Parameter.behavioralFeature>
                    <Foundation.Core.BehavioralFeature xmi.idref="xmi.12"/>
                  </Foundation.Core.Parameter.behavioralFeature>
                  <Foundation.Core.Parameter.type>
                    <Foundation.Core.Classifier xmi.idref="xmi.14"/>
                  </Foundation.Core.Parameter.type>
                </Foundation.Core.Parameter>
                <Foundation.Core.Parameter xmi.id="xmi.15" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fec">
                  <Foundation.Core.ModelElement.name>myArgument</Foundation.Core.ModelElement.name>
                  <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
                  <Foundation.Core.Parameter.kind xmi.value="in"/>
                  <Foundation.Core.Parameter.behavioralFeature>
                    <Foundation.Core.BehavioralFeature xmi.idref="xmi.12"/>
                  </Foundation.Core.Parameter.behavioralFeature>
                  <Foundation.Core.Parameter.type>
                    <Foundation.Core.Classifier xmi.idref="xmi.16"/>
                  </Foundation.Core.Parameter.type>
                </Foundation.Core.Parameter>
              </Foundation.Core.BehavioralFeature.parameter>
            </Foundation.Core.Operation>
          </Foundation.Core.Classifier.feature>
        </Foundation.Core.Class>
        <Foundation.Core.DataType xmi.id="xmi.14" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fef">
          <Foundation.Core.ModelElement.name>void</Foundation.Core.ModelElement.name>
          <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
          <Foundation.Core.ModelElement.namespace>
            <Foundation.Core.Namespace xmi.idref="xmi.1"/>
          </Foundation.Core.ModelElement.namespace>
        </Foundation.Core.DataType>
        <Foundation.Core.DataType xmi.id="xmi.16" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7feb">
          <Foundation.Core.ModelElement.name>int</Foundation.Core.ModelElement.name>
          <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
          <Foundation.Core.ModelElement.namespace>
            <Foundation.Core.Namespace xmi.idref="xmi.1"/>
          </Foundation.Core.ModelElement.namespace>
        </Foundation.Core.DataType>
      </Foundation.Core.Namespace.ownedElement>
    </Model_Management.Model>
  </XMI.content>
</XMI>
XXX;
# ---------------------------------------------------------
$demo["r1format"] = "xmi";
$demo["r2format"] = "xmi";
savedemo();
# ---------------------------------------------------------

##############################################################################

# ---------------------------------------------------------
$demo["instructions"] = <<<XXX
To illustrate the meta encoding of XMI files.

XXX;
# ---------------------------------------------------------
$demo["r1"] = <<<XXX
<?xml version="1.0" encoding="UTF-8"?>
<XMI xmi.version="1.0">
  <XMI.header>
    <XMI.documentation>
      <XMI.exporter>Novosoft UML Library</XMI.exporter>
      <XMI.exporterVersion>0.4.20</XMI.exporterVersion>
    </XMI.documentation>
    <XMI.metamodel xmi.name="UML" xmi.version="1.3"/>
  </XMI.header>
  <XMI.content>
    <Model_Management.Model xmi.id="xmi.1" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-8000">
      <Foundation.Core.ModelElement.name>myModel</Foundation.Core.ModelElement.name>
      <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
      <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
      <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
      <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
      <Foundation.Core.Namespace.ownedElement>
        <Foundation.Core.Class xmi.id="xmi.2" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7ffc">
          <Foundation.Core.ModelElement.name>MyClass</Foundation.Core.ModelElement.name>
          <Foundation.Core.ModelElement.visibility xmi.value="public"/>
          <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
          <Foundation.Core.Class.isActive xmi.value="false"/>
          <Foundation.Core.ModelElement.namespace>
            <Foundation.Core.Namespace xmi.idref="xmi.1"/>
          </Foundation.Core.ModelElement.namespace>
          <Foundation.Core.Classifier.feature>
            <Foundation.Core.Attribute xmi.id="xmi.3" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7ff3">
              <Foundation.Core.ModelElement.name>myStaticAttribute</Foundation.Core.ModelElement.name>
              <Foundation.Core.ModelElement.visibility xmi.value="public"/>
              <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
              <Foundation.Core.Feature.ownerScope xmi.value="classifier"/>
              <Foundation.Core.StructuralFeature.multiplicity>
                <Foundation.Data_Types.Multiplicity xmi.id="xmi.4">
                  <Foundation.Data_Types.Multiplicity.range>
                    <Foundation.Data_Types.MultiplicityRange xmi.id="xmi.5">
                      <Foundation.Data_Types.MultiplicityRange.lower>1</Foundation.Data_Types.MultiplicityRange.lower>
                      <Foundation.Data_Types.MultiplicityRange.upper>1</Foundation.Data_Types.MultiplicityRange.upper>
                    </Foundation.Data_Types.MultiplicityRange>
                  </Foundation.Data_Types.Multiplicity.range>
                </Foundation.Data_Types.Multiplicity>
              </Foundation.Core.StructuralFeature.multiplicity>
              <Foundation.Core.StructuralFeature.changeability xmi.value="changeable"/>
              <Foundation.Core.StructuralFeature.targetScope xmi.value="instance"/>
              <Foundation.Core.Attribute.initialValue>
                <Foundation.Data_Types.Expression xmi.id="xmi.6">
                  <Foundation.Data_Types.Expression.language>Java</Foundation.Data_Types.Expression.language>
                  <Foundation.Data_Types.Expression.body></Foundation.Data_Types.Expression.body>
                </Foundation.Data_Types.Expression>
              </Foundation.Core.Attribute.initialValue>
              <Foundation.Core.Feature.owner>
                <Foundation.Core.Classifier xmi.idref="xmi.2"/>
              </Foundation.Core.Feature.owner>
              <Foundation.Core.ModelElement.taggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.7">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>transient</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.3"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.8">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>volatile</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.3"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
              </Foundation.Core.ModelElement.taggedValue>
            </Foundation.Core.Attribute>
            <Foundation.Core.Attribute xmi.id="xmi.9" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7ff0">
              <Foundation.Core.ModelElement.name>myDynamicAttribute</Foundation.Core.ModelElement.name>
              <Foundation.Core.ModelElement.visibility xmi.value="public"/>
              <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
              <Foundation.Core.Feature.ownerScope xmi.value="instance"/>
              <Foundation.Core.StructuralFeature.multiplicity>
                <Foundation.Data_Types.Multiplicity xmi.idref="xmi.4"/>
              </Foundation.Core.StructuralFeature.multiplicity>
              <Foundation.Core.StructuralFeature.changeability xmi.value="changeable"/>
              <Foundation.Core.StructuralFeature.targetScope xmi.value="instance"/>
              <Foundation.Core.Feature.owner>
                <Foundation.Core.Classifier xmi.idref="xmi.2"/>
              </Foundation.Core.Feature.owner>
              <Foundation.Core.ModelElement.taggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.10">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>transient</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.9"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
                <Foundation.Extension_Mechanisms.TaggedValue xmi.id="xmi.11">
                  <Foundation.Extension_Mechanisms.TaggedValue.tag>volatile</Foundation.Extension_Mechanisms.TaggedValue.tag>
                  <Foundation.Extension_Mechanisms.TaggedValue.value>false</Foundation.Extension_Mechanisms.TaggedValue.value>
                  <Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                    <Foundation.Core.ModelElement xmi.idref="xmi.9"/>
                  </Foundation.Extension_Mechanisms.TaggedValue.modelElement>
                </Foundation.Extension_Mechanisms.TaggedValue>
              </Foundation.Core.ModelElement.taggedValue>
            </Foundation.Core.Attribute>
            <Foundation.Core.Operation xmi.id="xmi.12" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fee">
              <Foundation.Core.ModelElement.name>myMethod</Foundation.Core.ModelElement.name>
              <Foundation.Core.ModelElement.visibility xmi.value="public"/>
              <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
              <Foundation.Core.Feature.ownerScope xmi.value="instance"/>
              <Foundation.Core.BehavioralFeature.isQuery xmi.value="false"/>
              <Foundation.Core.Operation.concurrency xmi.value="sequential"/>
              <Foundation.Core.Operation.isRoot xmi.value="false"/>
              <Foundation.Core.Operation.isLeaf xmi.value="false"/>
              <Foundation.Core.Operation.isAbstract xmi.value="false"/>
              <Foundation.Core.Feature.owner>
                <Foundation.Core.Classifier xmi.idref="xmi.2"/>
              </Foundation.Core.Feature.owner>
              <Foundation.Core.BehavioralFeature.parameter>
                <Foundation.Core.Parameter xmi.id="xmi.13" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fed">
                  <Foundation.Core.ModelElement.name>return</Foundation.Core.ModelElement.name>
                  <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
                  <Foundation.Core.Parameter.kind xmi.value="return"/>
                  <Foundation.Core.Parameter.behavioralFeature>
                    <Foundation.Core.BehavioralFeature xmi.idref="xmi.12"/>
                  </Foundation.Core.Parameter.behavioralFeature>
                  <Foundation.Core.Parameter.type>
                    <Foundation.Core.Classifier xmi.idref="xmi.14"/>
                  </Foundation.Core.Parameter.type>
                </Foundation.Core.Parameter>
                <Foundation.Core.Parameter xmi.id="xmi.15" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fec">
                  <Foundation.Core.ModelElement.name>myArgument</Foundation.Core.ModelElement.name>
                  <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
                  <Foundation.Core.Parameter.kind xmi.value="in"/>
                  <Foundation.Core.Parameter.behavioralFeature>
                    <Foundation.Core.BehavioralFeature xmi.idref="xmi.12"/>
                  </Foundation.Core.Parameter.behavioralFeature>
                  <Foundation.Core.Parameter.type>
                    <Foundation.Core.Classifier xmi.idref="xmi.16"/>
                  </Foundation.Core.Parameter.type>
                </Foundation.Core.Parameter>
              </Foundation.Core.BehavioralFeature.parameter>
            </Foundation.Core.Operation>
          </Foundation.Core.Classifier.feature>
        </Foundation.Core.Class>
        <Foundation.Core.DataType xmi.id="xmi.14" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7fef">
          <Foundation.Core.ModelElement.name>void</Foundation.Core.ModelElement.name>
          <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
          <Foundation.Core.ModelElement.namespace>
            <Foundation.Core.Namespace xmi.idref="xmi.1"/>
          </Foundation.Core.ModelElement.namespace>
        </Foundation.Core.DataType>
        <Foundation.Core.DataType xmi.id="xmi.16" xmi.uuid="127-0-0-1-587175e0:105a31639e2:-7feb">
          <Foundation.Core.ModelElement.name>int</Foundation.Core.ModelElement.name>
          <Foundation.Core.ModelElement.isSpecification xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isRoot xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isLeaf xmi.value="false"/>
          <Foundation.Core.GeneralizableElement.isAbstract xmi.value="false"/>
          <Foundation.Core.ModelElement.namespace>
            <Foundation.Core.Namespace xmi.idref="xmi.1"/>
          </Foundation.Core.ModelElement.namespace>
        </Foundation.Core.DataType>
      </Foundation.Core.Namespace.ownedElement>
    </Model_Management.Model>
  </XMI.content>
</XMI>

XXX;
# ---------------------------------------------------------
$demo["r1format"] = "xmi";
$demo["r2format"] = "meta";
savedemo();
# ---------------------------------------------------------

?>