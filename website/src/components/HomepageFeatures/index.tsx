import type { ReactNode } from "react";
import clsx from "clsx";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";
import Translate, { translate } from "@docusaurus/Translate";

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<"svg">>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: translate({ id: "homepage.features.commandLine.title", message: "Command Line" }),
    Svg: require("@site/static/img/command_line.svg").default,
    description: (
      <>
        <Translate id="homepage.features.commandLine.description">
          Learn the basic Linux commands that you can use to get around Linux
          systems.
        </Translate>
      </>
    ),
  },
  {
    title: translate({ id: "homepage.features.virtualMachine.title", message: "Virtual Machine" }),
    Svg: require("@site/static/img/virtual_box_logo.svg").default,
    description: (
      <>
        <Translate id="homepage.features.virtualMachine.description">
          Understand how to use virtualization technology to run several
          operating systems on your device.
        </Translate>
      </>
    ),
  },
  {
    title: translate({ id: "homepage.features.tiling.title", message: "Tiling Window Manager" }),
    Svg: require("@site/static/img/sway.svg").default,
    description: (
      <>
        <Translate id="homepage.features.tiling.description">
          Learn how to use efficiently a tiling window manager like Sway.
        </Translate>
      </>
    ),
  },
];

function Feature({ title, Svg, description }: FeatureItem) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => <Feature key={idx} {...props} />)}
        </div>
      </div>
    </section>
  );
}
